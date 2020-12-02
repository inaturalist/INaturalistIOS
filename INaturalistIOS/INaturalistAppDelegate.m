//
//  INaturalistAppDelegate.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

@import Firebase;
@import Fabric;
@import Crashlytics;
@import Realm;
@import FBSDKCoreKit;
@import GoogleSignIn;
@import UIColor_HTMLColors;
@import JDStatusBarNotification;
@import FBSDKCoreKit;
@import SDWebImage;

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
#import "NSURL+INaturalist.h"
#import "Fave.h"
#import "NewsItem.h"
#import "ExploreTaxonRealm.h"
#import "ABSorter.h"
#import "ObservationAPI.h"
#import "ExploreUpdate.h"
#import "ExploreUpdateRealm.h"
#import "NewsPagerViewController.h"
#import "UpdatesViewController.h"
#import "INatReachability.h"
#import "ExploreDeletedRecord.h"
#import "Guide.h"
#import "ExploreGuideRealm.h"
#import "ExploreObservationRealm.h"
#import "iNaturalist-Swift.h"
#import "ImageStore.h"

@interface INaturalistAppDelegate () {
    NSManagedObjectModel *managedObjectModel;
}

@property UIBackgroundTaskIdentifier backgroundFetchTask;

@end

@implementation INaturalistAppDelegate

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[INatReachability sharedClient] startMonitoring];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [[INatReachability sharedClient] stopMonitoring];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<NSString *, id> *)options {
    
    BOOL handled = [[FBSDKApplicationDelegate sharedInstance] application:application
                                                                    openURL:url
                                                          sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                                                                 annotation:options[UIApplicationOpenURLOptionsAnnotationKey]
                      ];
    
    if (!handled) {
        handled = [[GIDSignIn sharedInstance] handleURL:url
                                      sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                                             annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
    }
    
    return handled;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self setupAnalytics];
    
    // never log any events with facebook analytics
    [FBSDKSettings setCodelessDebugLogEnabled:@(NO)];
    [FBSDKSettings setAutoLogAppEventsEnabled:@(NO)];

    // required for facebook login
    [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
    
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    // we need a login controller to handle google auth, can't do this in the background
    self.loginController = [[LoginController alloc] init];

    [self showLoadingScreen];
    
    [self configureApplication];

    // Use Crashlytics for crash reporting
    if ([Analytics canTrack]) {
        [Fabric with:@[[Crashlytics class]]];
    }

    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    __block UIBackgroundTaskIdentifier taskId = [application beginBackgroundTaskWithName:@"PhotoCleanUp" expirationHandler:^{
        [application endBackgroundTask:taskId];
        taskId = UIBackgroundTaskInvalid;
    }];
    
    [self cleanupDatabaseExecutionSeconds:10];
    
    [self cleanupPhotosExecutionSeconds:20];
    
    [application endBackgroundTask:taskId];
    taskId = UIBackgroundTaskInvalid;
}

- (void)setupAnalytics {
    // setup analytics
    [[Analytics sharedClient] event:kAnalyticsEventAppLaunch];    
}

- (void)showLoadingScreen {
    UIViewController *loadingVC = [[UIViewController alloc] initWithNibName:nil bundle:nil];
    loadingVC.view.backgroundColor = [UIColor inatTint];
    
    UIImageView *launchImageView = ({
        UIImageView *iv = [[UIImageView alloc] initWithFrame:loadingVC.view.bounds];
        iv.image = [UIImage imageNamed:@"inat-white-logo"];
        iv.contentMode = UIViewContentModeScaleAspectFit;
        
        iv;
    });
 
    UILabel *updatingDatabaseLabel = ({
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.text = NSLocalizedString(@"Updating database...", @"Title for progress view when migrating db");
        label.textColor = [UIColor whiteColor];
        label.numberOfLines = 0;

        label;
    });
    
    UIActivityIndicatorView *spinner = ({
        UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        
        view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        view.center = CGPointMake(loadingVC.view.center.x, loadingVC.view.frame.size.height * .75);
        [view startAnimating];
        
        view;
    });
    
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[ launchImageView, updatingDatabaseLabel, spinner ]];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 50.0f;
    stack.alignment = UIStackViewAlignmentCenter;
    
    [loadingVC.view addSubview:stack];

    [stack.centerYAnchor constraintEqualToAnchor:loadingVC.view.centerYAnchor].active = YES;
    [stack.centerXAnchor constraintEqualToAnchor:loadingVC.view.centerXAnchor].active = YES;
    [launchImageView.widthAnchor constraintEqualToConstant:200.0f].active = YES;
    [launchImageView.heightAnchor constraintEqualToConstant:200.0f].active = YES;
    
    [self.window setRootViewController:loadingVC];
}

- (void)configureApplication {
    
    [self configureOAuth2Client];
    [self configureGlobalStyles];    
    //[self configureRestKit];

	RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    NSLog(@"config file URL %@", config.fileURL);
	config.schemaVersion = 20;
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
        if (oldSchemaVersion < 11) {
            // set all user syncedAt to distant past
            [migration enumerateObjects:ExploreUserRealm.className
                                  block:^(RLMObject * _Nullable oldObject, RLMObject * _Nullable newObject) {
                                      newObject[@"syncedAt"] = [NSDate distantPast];
                                  }];
        }
        if (oldSchemaVersion < 12) {
            [migration enumerateObjects:ExploreDeletedRecord.className
                                  block:^(RLMObject * _Nullable oldObject, RLMObject * _Nullable newObject) {
                if (oldObject[@"recordId"] != 0 && oldObject[@"modelName"]) {
                    newObject[@"modelAndRecordId"] = [NSString stringWithFormat:@"%ld-%@",
                                                      (long)oldObject[@"recordId"], oldObject[@"modelName"]];
                } else {
                    // just drop it if we can't make a primary key
                    [migration deleteObject:newObject];
                }
            }];
        }
        if (oldSchemaVersion < 17) {
            // TODO: update migration code
            
            /*
            for (Guide *g in [Guide allObjects]) {
                id value = [ExploreGuideRealm valueForCoreDataModel:g];
                if (!value) {
                    // not the end of the world if we can't migrate a core data guide
                    continue;
                }
                
                @try {
                    [migration createObject:ExploreGuideRealm.className withValue:value];
                } @catch (NSException *exception) {
                    // not the end of the world if this migration fails
                    continue;
                }
            }
             */
        }
        if (oldSchemaVersion < 19) {
            // added a primary key to ExploreObservationPhotoRealm
            NSMutableSet *attachedPhotos = [NSMutableSet set];
            [migration enumerateObjects:ExploreObservationRealm.className
                                  block:^(RLMObject * _Nullable oldObject, RLMObject * _Nullable newObject) {
                RLMArray <ExploreObservationPhotoRealm> *photos = oldObject[@"observationPhotos"];
                for (ExploreObservationPhotoRealm *op in photos) {
                    [attachedPhotos addObject:op];
                }
            }];
                        
            [migration enumerateObjects:ExploreObservationPhotoRealm.className
                                  block:^(RLMObject *oldObject, RLMObject *newObject) {
                if (![attachedPhotos containsObject:oldObject]) {
                    [migration deleteObject:newObject];
                }
            }];
        }
        
        
        if (oldSchemaVersion < 20) {
            // added a primary key to ExploreFaveRealm
            NSMutableSet *seenFaveIds = [NSMutableSet set];
            [migration enumerateObjects:ExploreFaveRealm.className
                                  block:^(RLMObject *oldObject, RLMObject *newObject) {
                NSInteger faveId = [oldObject[@"faveId"] integerValue];
                
                if (faveId == 0) {
                    [migration deleteObject:newObject];
                    return;
                }
                
                if ([seenFaveIds containsObject:@(faveId)]) {
                    [migration deleteObject:newObject];
                    return;
                }
                
                [seenFaveIds addObject:@(faveId)];
            }];
        }
    };
    [RLMRealmConfiguration setDefaultConfiguration:config];
    
    // on every launch, do some housekeeping of deleted records
    [self cleanupDeletedRecords];
    
    if (![self.loginController isLoggedIn]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [((INaturalistAppDelegate *)[UIApplication sharedApplication].delegate) showInitialSignupUI];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [((INaturalistAppDelegate *)[UIApplication sharedApplication].delegate) showMainUI];
            
            ExploreUserRealm *me = self.loginController.meUserLocal;
            NSString *identifier = [NSString stringWithFormat:@"%ld", (long)me.userId];
            [[Analytics sharedClient] registerUserWithIdentifier:identifier];
        });
    }
}

- (void)cleanupDeletedRecords {
    RLMRealm *realm = [RLMRealm defaultRealm];
    if (self.loginController.isLoggedIn) {
        // if we're logged in, clean up any synced deleted records
        [realm beginWriteTransaction];
        [realm deleteObjects:[ExploreDeletedRecord syncedRecords]];
        [realm commitWriteTransaction];
    } else {
        // if we're not logged in, deleted records aren't meaningful
        // if there are any around, they're stale and should be trashed
        [realm beginWriteTransaction];
        [realm deleteObjects:[ExploreDeletedRecord allObjects]];
        [realm commitWriteTransaction];
    }
}

- (void)cleanupDatabaseExecutionSeconds:(NSInteger)allowedExecutionSeconds {
    NSDate *beginDate = [NSDate date];
    
    // we need to periodically delete unattached child records
    // for example, an observation photo without an observation isn't
    // meaningful
    RLMRealm *realm = [RLMRealm defaultRealm];
    NSPredicate *nilObsPredicate = [NSPredicate predicateWithFormat:@"observations.@count == 0"];
    
    NSArray *childClassesToCleanup = @[
        ExploreObservationPhotoRealm.class,
        ExploreCommentRealm.class,
        ExploreIdentificationRealm.class,
        ExploreFaveRealm.class,
        ExploreObsFieldValueRealm.class,
        ExploreProjectObservationRealm.class,
    ];
    
    NSInteger deletedItems = 0;
    NSInteger classesCompleted = 0;
    
    for (Class klass in childClassesToCleanup) {
        RLMResults *unattachedObjects = [klass objectsWithPredicate:nilObsPredicate];
        deletedItems += unattachedObjects.count;

        [realm beginWriteTransaction];
        [realm deleteObjects:unattachedObjects];
        [realm commitWriteTransaction];
        
        NSDate *afterDelete = [NSDate date];
        NSTimeInterval elapsedAfterDelete = [afterDelete timeIntervalSinceDate:beginDate];
        if (elapsedAfterDelete > allowedExecutionSeconds) {
            break;
        }
        classesCompleted += 1;
    }
    
    NSDate *endDate = [NSDate date];
    NSTimeInterval elapsed = [endDate timeIntervalSinceDate:beginDate];
    
    [[Analytics sharedClient] event:@"CleanupRealmDatabase"
                     withProperties:@{
                         @"DeletedCount": @(deletedItems),
                         @"ClassesPlanned": @(childClassesToCleanup.count),
                         @"ClassesCompleted": @(classesCompleted),
                         @"ExecutionElapsed": @(elapsed),
                     }];
}

- (void)cleanupPhotosExecutionSeconds:(NSInteger)allowedExecutionSeconds {
    NSDate *beginDate = [NSDate date];
    
    RLMResults *allPhotos = [ExploreObservationPhotoRealm allObjects];
    NSMutableArray *validPhotoKeys = [NSMutableArray arrayWithCapacity:allPhotos.count];
    NSMutableArray *syncedPhotoKeys = [NSMutableArray arrayWithCapacity:allPhotos.count];
    for (ExploreObservationPhotoRealm *op in allPhotos) {
        if (op.photoKey && op.photoKey.length > 0) {
            [validPhotoKeys addObject:op.photoKey];
            if (op.timeSynced) {
                [syncedPhotoKeys addObject:op.photoKey];
            }
        }
    }
    
    NSDate *afterPhotoKeyListDate = [NSDate date];
    NSTimeInterval elapsedAfterList = [afterPhotoKeyListDate timeIntervalSinceDate:beginDate];
    
    [[ImageStore sharedImageStore] cleanupImageStoreUsingValidPhotoKeys:validPhotoKeys
                                                        syncedPhotoKeys:syncedPhotoKeys
                                                   allowedExecutionTime:allowedExecutionSeconds-elapsedAfterList];
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
    if (![self.window.rootViewController isKindOfClass:[INatTabBarController class]]) {
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

@end
