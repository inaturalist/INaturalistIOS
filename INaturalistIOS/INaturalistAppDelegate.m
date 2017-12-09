//
//  INaturalistAppDelegate.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <IFTTTLaunchImage/UIImage+IFTTTLaunchImage.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>
#import <JDStatusBarNotification/JDStatusBarNotification.h>
#import <GooglePlus/GPPURLHandler.h>

#import "INaturalistAppDelegate.h"
#import "Observation.h"
#import "ObservationField.h"
#import "ObservationFieldValue.h"
#import "ObservationPhoto.h"
#import "Project.h"
#import "ProjectObservation.h"
#import "ProjectObservationField.h"
#import "ProjectUser.h"
#import "Taxon.h"
#import "TaxonPhoto.h"
#import "Comment.h"
#import "Identification.h"
#import "User.h"
#import "NXOAuth2.h"
#import "UIColor+INaturalist.h"
#import "Analytics.h"
#import "LoginController.h"
#import "INatUITabBarController.h"
#import "NSURL+INaturalist.h"
#import "DeletedRecord.h"
#import "Fave.h"
#import "NewsItem.h"
#import "ExploreTaxonRealm.h"
#import "ABSorter.h"
#import "ObservationAPI.h"
#import "ExploreUpdate.h"
#import "ExploreUpdateRealm.h"
#import "NewsPagerViewController.h"
#import "UpdatesViewController.h"

@interface INaturalistAppDelegate () {
    NSManagedObjectModel *managedObjectModel;
    RKManagedObjectStore *_inatObjectStore;
}

@property (readonly) RKManagedObjectStore *inatObjectStore;
@property UIBackgroundTaskIdentifier backgroundFetchTask;

@end

@implementation INaturalistAppDelegate


- (void)applicationDidBecomeActive:(UIApplication *)application {
	[FBSDKAppEvents activateApp];
    
    [self loadUpdatesWithCompletionHandler:nil];
    
    [self clearOutdatedCaches];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
         
         return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                         openURL:url
                                               sourceApplication:sourceApplication
                                                      annotation:annotation] 
          || 
	      
	      [GPPURLHandler handleURL:url
	                 sourceApplication:sourceApplication
	                        annotation:annotation];
}

- (void)loadUpdatesWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    UIApplication *application = [UIApplication sharedApplication];
    
    if (!self.loginController) {
        self.loginController = [[LoginController alloc] init];
    }
    
    if (!self.loginController.isLoggedIn) {
        if (completionHandler) {
            completionHandler(UIBackgroundFetchResultNoData);
        }
    } else {
        NSNumber *userIdObj = nil;
        if ([[NSUserDefaults standardUserDefaults] valueForKey:kINatUserIdPrefKey]) {
            userIdObj = [[NSUserDefaults standardUserDefaults] valueForKey:kINatUserIdPrefKey];
        }
        
        if (!userIdObj) {
            if (completionHandler) {
                completionHandler(UIBackgroundFetchResultNoData);
            }
        } else {
            NSInteger userId = userIdObj.integerValue;
            
            self.backgroundFetchTask = [application beginBackgroundTaskWithExpirationHandler:^{
                [application endBackgroundTask:self.backgroundFetchTask];
                self.backgroundFetchTask = UIBackgroundTaskInvalid;
            }];
            
            __weak typeof(self)weakSelf = self;
            ObservationAPI *api = [[ObservationAPI alloc] init];
            [api updatesWithHandler:^(NSArray *results, NSInteger count, NSError *error) {
                
                if (error) {
                    if (completionHandler) {
                        [[Analytics sharedClient] event:kAnalyticsEventBackgroundFetchFailed
                                         withProperties:@{
                                                          @"reason": error.localizedDescription,
                                                          }];
                        completionHandler(UIBackgroundFetchResultFailed);
                    }
                    [application endBackgroundTask:weakSelf.backgroundFetchTask];
                    weakSelf.backgroundFetchTask = UIBackgroundTaskInvalid;
                    return;
                }
                
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"resourceOwnerId == %d", userId];
                NSArray *myResults = [results filteredArrayUsingPredicate:predicate];
                
                NSMutableSet *obsIds = [NSMutableSet set];
                for (ExploreUpdate *eu in myResults) {
                    [obsIds addObject:@(eu.resourceId)];
                }
                [weakSelf loadObservationsForIds:[obsIds allObjects]];
                
                RLMRealm *realm = [RLMRealm defaultRealm];
                [realm beginWriteTransaction];
                // all results get written to Realm
                for (ExploreUpdate *eu in results) {
                    ExploreUpdateRealm *eur = [[ExploreUpdateRealm alloc] initWithMantleModel:eu];
                    [realm addOrUpdateObject:eur];
                }
                [realm commitWriteTransaction];
                UIViewController *rootVC = [[[UIApplication sharedApplication] keyWindow] rootViewController];
                if ([rootVC isKindOfClass:[INatUITabBarController class]]) {
                    [((INatUITabBarController *)rootVC) setUpdatesBadge];
                }
                
                if (completionHandler) {
                    completionHandler(UIBackgroundFetchResultNewData);
                }
                
                [application endBackgroundTask:weakSelf.backgroundFetchTask];
                weakSelf.backgroundFetchTask = UIBackgroundTaskInvalid;
            }];
        }
    }
}

- (void)loadObservationsForIds:(NSArray *)obsIds {
    for (NSNumber *obsId in obsIds) {
        NSString *resourcePath = [NSString stringWithFormat:@"/observations/%ld.json",
                                  (unsigned long)obsId.integerValue];
        [[RKObjectManager sharedManager] loadObjectsAtResourcePath:resourcePath usingBlock:^(RKObjectLoader *loader) {
            loader.objectMapping = [Observation mapping];
            loader.onDidLoadObject = ^(Observation *obs) {
                [[[RKObjectManager sharedManager] objectStore] save:nil];
            };
            loader.onDidFailWithError = ^(NSError *error) {
                // do nothing?
            };
        }];
    }
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [self loadUpdatesWithCompletionHandler:completionHandler];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setupAnalytics];
    
    [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
    
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    // we need a login controller to handle google auth, can't do this in the background
    self.loginController = [[LoginController alloc] init];

    [self showLoadingScreen];
    
    [self configureApplication];
    
    return YES;
}

- (void)setupAnalytics {
    // setup analytics
    [[Analytics sharedClient] event:kAnalyticsEventAppLaunch];    
}

- (void)showLoadingScreen {
    UIViewController *loadingVC = [[UIViewController alloc] initWithNibName:nil bundle:nil];
    
    UIImageView *launchImageView = ({
        UIImageView *iv = [[UIImageView alloc] initWithFrame:loadingVC.view.bounds];
        iv.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        iv.contentMode = UIViewContentModeScaleAspectFill;
        iv.image = [UIImage imageNamed:@"Launch_Screen_4s_launch_screen_6plus.png"];
        
        iv;
    });
    [loadingVC.view addSubview:launchImageView];
    
    UIActivityIndicatorView *spinner = ({
        UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        
        view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        view.center = CGPointMake(loadingVC.view.center.x, loadingVC.view.frame.size.height * .75);
        [view startAnimating];
        
        view;
    });
    [loadingVC.view addSubview:spinner];
    
    [self.window setRootViewController:loadingVC];
}

- (void)configureApplication {
    
	RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
	config.schemaVersion = 9;
    config.migrationBlock = ^(RLMMigration *migration, uint64_t oldSchemaVersion) {
        if (oldSchemaVersion < 1) {
            // add searchable (ie diacritic-less) taxon names
            [migration enumerateObjects:ExploreTaxonRealm.className
                                  block:^(RLMObject *oldObject, RLMObject *newObject) {
                                      newObject[@"searchableScientificName"] = [oldObject[@"scientificName"] stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:[NSLocale currentLocale]];
                                      newObject[@"searchableCommonName"] = [oldObject[@"commonName"] stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:[NSLocale currentLocale]];
                                  }];
        }
        if (oldSchemaVersion < 5) {
            // add viewed to updates.
            [migration enumerateObjects:ExploreUpdateRealm.className
                                  block:^(RLMObject * _Nullable oldObject, RLMObject * _Nullable newObject) {
                                      newObject[@"viewed"] = @(YES);
                                  }];
        }
        if (oldSchemaVersion < 8) {
            // add locally viewed to updates.
            [migration enumerateObjects:ExploreUpdateRealm.className
                                  block:^(RLMObject * _Nullable oldObject, RLMObject * _Nullable newObject) {
                                      newObject[@"viewedLocally"] = @(YES);
                                  }];
        }
    };
    [RLMRealmConfiguration setDefaultConfiguration:config];
    
    [self configureOAuth2Client];
    
    [self configureGlobalStyles];
    
    [self configureRestKit];
    
    // if we're not logged in, deleted records aren't meaningful
    // if there are any around, they're stale and should be trashed
    if (!self.loginController.isLoggedIn) {
        for (DeletedRecord *record in [DeletedRecord allObjects]) {
            [record deleteEntity];
        }
    }
    NSError *error = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
    if (error) {
        [[Analytics sharedClient] debugLog:@"Object Store Failed Removing Stale Deleted Records at Launch"];
        [[Analytics sharedClient] debugLog:error.localizedDescription];
    }
    
    if (![self.loginController isLoggedIn]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [((INaturalistAppDelegate *)[UIApplication sharedApplication].delegate) showInitialSignupUI];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [((INaturalistAppDelegate *)[UIApplication sharedApplication].delegate) showMainUI];
            
            User *me = self.loginController.fetchMe;
            [[Analytics sharedClient] registerUserWithIdentifier:me.recordID.stringValue];
        });
    }
}


- (void)configureGlobalStyles {
    // set global styles
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        
        [[UITabBar appearance] setBarStyle:UIBarStyleDefault];
        
        [[UITabBar appearance] setTintColor:[UIColor inatTint]];
        
        // tints for UITabBarItem images are set on the images in the VCs, via [UIImage -imageWithRenderingMode:]
        [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName: [UIColor inatTint] }
                                                             forState:UIControlStateSelected];
        [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName: [UIColor inatInactiveGreyTint] }
                                                             forState:UIControlStateNormal];
        
        [[UINavigationBar appearance] setBarStyle:UIBarStyleDefault];
        [[UINavigationBar appearance] setTintColor:[UIColor inatTint]];
        [[UISearchBar appearance] setBarStyle:UIBarStyleDefault];
        [[UIBarButtonItem appearance] setTintColor:[UIColor inatTint]];
        [[UISegmentedControl appearance] setTintColor:[UIColor inatTint]];
    }
        
    [JDStatusBarNotification setDefaultStyle:^JDStatusBarStyle *(JDStatusBarStyle *style) {
        style.barColor = [UIColor colorWithHexString:@"#969696"];
        style.textColor = [UIColor whiteColor];
        return style;
    }];
}

- (void)reconfigureForNewBaseUrl {
    [self configureRestKit];
}

- (RKManagedObjectStore *)inatObjectStore {
    if (!_inatObjectStore) {
        _inatObjectStore = [RKManagedObjectStore objectStoreWithStoreFilename:@"inaturalist.sqlite"
                                                        usingSeedDatabaseName:nil
                                                           managedObjectModel:[self getManagedObjectModel]
                                                                     delegate:self];
    }
    
    return _inatObjectStore;
}

- (void)rebuildCoreData {
    [Comment deleteAll];
    [Identification deleteAll];
    [User deleteAll];
    [Observation deleteAll];
    [ObservationPhoto deleteAll];
    [ProjectUser deleteAll];
    [ProjectObservation deleteAll];
    [NewsItem deleteAll];
    [ObservationFieldValue deleteAll];
    [User deleteAll];
    
    for (DeletedRecord *dr in [DeletedRecord allObjects]) {
        [dr deleteEntity];
    }
    
    NSError *error = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kInatCoreDataRebuiltNotification
                                                        object:nil];
}

- (void)configureRestKit
{
    RKObjectManager *manager = [RKObjectManager objectManagerWithBaseURL:[NSURL inat_baseURL]];
    manager.objectStore = [self inatObjectStore];
    
    // Auth
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [manager.client setValue:[defaults objectForKey:INatTokenPrefKey] forHTTPHeaderField:@"Authorization"];
    [manager.client setAuthenticationType: RKRequestAuthenticationTypeNone];
    
    // User Agent
    UIDevice *d = [UIDevice currentDevice];
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *userAgent = [NSString stringWithFormat:@"iNaturalist/%@ (iOS %@ %@ %@)", 
                           appVersion,
                           d.systemName, 
                           d.systemVersion, 
                           d.model];
    [manager.client setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    NSDictionary *userAgentDict = [[NSDictionary alloc] initWithObjectsAndKeys:userAgent, @"UserAgent", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:userAgentDict];
    
    NSArray *models = [NSArray arrayWithObjects:
                       Observation.class, 
                       ObservationField.class,
                       ObservationFieldValue.class,
                       ObservationPhoto.class, 
                       Project.class, 
                       ProjectObservation.class, 
                       ProjectObservationField.class,
                       ProjectUser.class, 
                       Taxon.class,
                       TaxonPhoto.class,
					   Comment.class,
					   Identification.class,
					   User.class,
                       nil];
    NSString *underscored;
    NSString *pluralized;
    for (id model in models) {
        underscored = NSStringFromClass(model).underscore;
        pluralized = underscored.pluralize;
        // Routes
        [manager.router routeClass:model toResourcePath:[NSString stringWithFormat:@"/%@/:recordID", pluralized]];
        [manager.router routeClass:model
                    toResourcePath:[NSString stringWithFormat:@"/%@", pluralized] 
                         forMethod:RKRequestMethodPOST];
        
        // Serialization
        [manager.mappingProvider setObjectMapping:[model mapping] forKeyPath:underscored];
        [manager.mappingProvider setObjectMapping:[model mapping] forKeyPath:pluralized];
        [manager.mappingProvider setSerializationMapping:[model serializationMapping] forClass:model];
    }
    
    // Make sure RK knows how to parse simple dates
    NSDateFormatter* dateFormatter = [NSDateFormatter new];
    [dateFormatter  setDateFormat:@"yyyy-MM-dd"];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    dateFormatter.locale = [NSLocale currentLocale];
    [RKObjectMapping addDefaultDateFormatter:dateFormatter];
    
    [manager.client requestQueue].showsNetworkActivityIndicatorWhenBusy = YES;
    
    // DEBUG
//        RKLogConfigureByName("RestKit", RKLogLevelWarning);
//        RKLogConfigureByName("RestKit/Network", RKLogLevelTrace);
    //RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelTrace);
    //RKLogConfigureByName("RestKit/CoreData", RKLogLevelTrace);

    // END DEBUG
    
    [RKObjectManager setSharedManager:manager];
    [RKClient setSharedClient:manager.client];
    
    // setup photo object manager
    self.photoObjectManager = [RKObjectManager objectManagerWithBaseURL:[NSURL URLWithString:INatMediaBaseURL]];
    self.photoObjectManager.objectStore = [self inatObjectStore];
    [self.photoObjectManager.router routeClass:ObservationPhoto.class 
                                toResourcePath:@"/observation_photos/:recordID\\.json"];
    [self.photoObjectManager.router routeClass:ObservationPhoto.class
                                toResourcePath:@"/observation_photos\\.json"
                                     forMethod:RKRequestMethodPOST];
    [self.photoObjectManager.mappingProvider setObjectMapping:[ObservationPhoto.class mapping] forKeyPath:@"observation_photo"];
    [self.photoObjectManager.mappingProvider setObjectMapping:[ObservationPhoto.class mapping] forKeyPath:@"observation_photos"];
    [self.photoObjectManager.mappingProvider setSerializationMapping:[ObservationPhoto.class serializationMapping] 
                                                            forClass:ObservationPhoto.class];
    self.photoObjectManager.client.requestQueue.showsNetworkActivityIndicatorWhenBusy = YES;
    [self.photoObjectManager.client setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    [self.photoObjectManager.client setValue:[defaults objectForKey:INatTokenPrefKey] forHTTPHeaderField:@"Authorization"];
    [self.photoObjectManager.client setAuthenticationType: RKRequestAuthenticationTypeNone];
    self.photoObjectManager.client.timeoutInterval = 180.0;
    self.photoObjectManager.requestQueue.concurrentRequestsLimit = 2;
}

// get configured model, or perform migration if necessary
- (NSManagedObjectModel *)getManagedObjectModel
{
    if (managedObjectModel) {
        return managedObjectModel;
    }
    
    NSError *error = nil;
    NSArray *docDirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [docDirs objectAtIndex:0];
    NSString *storePath = [docDir stringByAppendingPathComponent:@"inaturalist.sqlite"];
    NSURL *storeURL = [NSURL fileURLWithPath:storePath];
    
    NSString *momPath = [[NSBundle mainBundle] pathForResource:@"iNaturalist" ofType:@"momd"];
    if (!momPath) {
        return [NSManagedObjectModel mergedModelFromBundles:nil];
    }
    
    
    NSURL *momURL = [NSURL fileURLWithPath:momPath];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
    
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption : @YES,
							  NSInferMappingModelAutomaticallyOption : @YES};
    
    if (![psc addPersistentStoreWithType:NSSQLiteStoreType
                           configuration:nil 
                                     URL:storeURL
                                 options:options 
                                   error:&error]) {
        [NSException raise:@"Failed to open database" format:@"%@", error.localizedDescription];
    }
    
    managedObjectModel = psc.managedObjectModel;
    return managedObjectModel;
}

-(void) configureOAuth2Client{
    NXOAuth2AccountStore *sharedStore = [NXOAuth2AccountStore sharedStore];
    for (NXOAuth2Account *account in [sharedStore accountsWithAccountType:kINatAuthService]) {
        // Do something with the account
        [[NXOAuth2AccountStore sharedStore] removeAccount:account];
    };
    //
    NSURL *authorizationURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/oauth/authorize?client_id=%@&redirect_uri=urn%%3Aietf%%3Awg%%3Aoauth%%3A2.0%%3Aoob&response_type=code", [NSURL inat_baseURLForAuthentication], INatClientID ]];
    [[NXOAuth2AccountStore sharedStore] setClientID:INatClientID
                                             secret:INatClientSecret
                                   authorizationURL:authorizationURL
                                           tokenURL:[NSURL URLWithString:@"/oauth/token"
                                                           relativeToURL:[NSURL inat_baseURLForAuthentication]]
                                        redirectURL:[NSURL URLWithString:@"urn:ietf:wg:oauth:2.0:oob"]
                                     forAccountType:kINatAuthService];
    
    for (NXOAuth2Account *account in [sharedStore accountsWithAccountType:kINatAuthServiceExtToken]) {
        // Do something with the account
        [[NXOAuth2AccountStore sharedStore] removeAccount:account];
    };
    [[NXOAuth2AccountStore sharedStore] setClientID:INatClientID
                                             secret:INatClientSecret
                                   authorizationURL:authorizationURL
                                           tokenURL:[NSURL URLWithString:@"/oauth/assertion_token.json"
                                                           relativeToURL:[NSURL inat_baseURLForAuthentication]]
                                        redirectURL:[NSURL URLWithString:@"urn:ietf:wg:oauth:2.0:oob"]
                                     forAccountType:kINatAuthServiceExtToken];
}

- (BOOL)loggedIn {
    return self.loginController.isLoggedIn;
}

- (void)showMainUI {
    if (![self.window.rootViewController isKindOfClass:[INatUITabBarController class]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIView *priorSnapshot = [[UIScreen mainScreen] snapshotViewAfterScreenUpdates:NO];
            
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
            UIViewController *mainVC = [storyboard instantiateInitialViewController];
            
            [mainVC.view addSubview:priorSnapshot];
            self.window.rootViewController = mainVC;
            
            [UIView animateWithDuration:0.65f
                             animations:^{
                                 priorSnapshot.alpha = 0.0f;
                             } completion:^(BOOL finished) {
                                 [priorSnapshot removeFromSuperview];
                             }];
        });
    }
}

- (void)showInitialSignupUI {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Onboarding" bundle:nil];
    UIViewController *onboardingVC = [storyboard instantiateInitialViewController];
    self.window.rootViewController = onboardingVC;
}

- (void)clearOutdatedCaches {
    for (ObservationPhoto *op in [ObservationPhoto allObjects]) {
        if ([op needsSync]) {
            continue;
        }
    }
}

@end

NSString *kInatCoreDataRebuiltNotification = @"kInatCoreDataRebuiltNotification";
