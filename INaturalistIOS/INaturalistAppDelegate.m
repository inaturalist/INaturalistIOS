//
//  INaturalistAppDelegate.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "INaturalistAppDelegate.h"
#import "List.h"
#import "ListedTaxon.h"
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
#import <Three20/Three20.h>
#import <FacebookSDK/FacebookSDK.h>
#import "GPPURLHandler.h"
#import "NXOAuth2.h"

@implementation INaturalistAppDelegate

@synthesize window = _window;
@synthesize photoObjectManager = _photoObjectManager;

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    return ([FBSession.activeSession handleOpenURL:url] || [GPPURLHandler handleURL:url
                                                                 sourceApplication:sourceApplication
                                                                        annotation:annotation]);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [self configureRestKit];
    [self configureThree20];
    [self configureOAuth2Client];
    
    return YES;
}

- (void)configureRestKit
{
    RKObjectManager* manager = [RKObjectManager objectManagerWithBaseURL:[NSURL URLWithString:INatBaseURL]];
    manager.objectStore = [RKManagedObjectStore objectStoreWithStoreFilename:@"inaturalist.sqlite" 
                                                       usingSeedDatabaseName:nil 
                                                          managedObjectModel:[self getManagedObjectModel] 
                                                                    delegate:self];
    
    // Auth
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //[RKClient.sharedClient setUsername:[defaults objectForKey:INatUsernamePrefKey]];
    //[RKClient.sharedClient setPassword:[defaults objectForKey:INatPasswordPrefKey]];
    [RKClient.sharedClient setValue:[defaults objectForKey:INatTokenPrefKey] forHTTPHeaderField:@"Authorization"];
    [RKClient.sharedClient setAuthenticationType: RKRequestAuthenticationTypeNone];
    
    // User Agent
    UIDevice *d = [UIDevice currentDevice];
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *userAgent = [NSString stringWithFormat:@"iNaturalist/%@ (iOS %@ %@ %@)", 
                           appVersion,
                           d.systemName, 
                           d.systemVersion, 
                           d.model];
    [RKClient.sharedClient setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    NSDictionary *userAgentDict = [[NSDictionary alloc] initWithObjectsAndKeys:userAgent, @"UserAgent", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:userAgentDict];
    
    NSArray *models = [NSArray arrayWithObjects:
                       List.class,
                       ListedTaxon.class,
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
    
    [[[RKObjectManager sharedManager] client] requestQueue].showsNetworkActivityIndicatorWhenBusy = YES;
    
    // DEBUG
//        RKLogConfigureByName("RestKit", RKLogLevelWarning);
//        RKLogConfigureByName("RestKit/Network", RKLogLevelTrace);
//        RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelTrace);
    // END DEBUG
    
    [RKObjectManager setSharedManager:manager];
    
    
    // setup photo object manager
    self.photoObjectManager = [RKObjectManager objectManagerWithBaseURL:[NSURL URLWithString:INatMediaBaseURL]];
    self.photoObjectManager.objectStore = [manager objectStore];
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

- (void)configureThree20
{
    [[TTURLRequestQueue mainQueue] setMaxContentLength:0];
    TTNavigator* navigator = [TTNavigator navigator];
    navigator.window = self.window;
}

-(void) configureOAuth2Client{
    NXOAuth2AccountStore *sharedStore = [NXOAuth2AccountStore sharedStore];
    for (NXOAuth2Account *account in [sharedStore accountsWithAccountType:kINatAuthService]) {
        // Do something with the account
        [[NXOAuth2AccountStore sharedStore] removeAccount:account];
    };
    //
    NSURL *authorizationURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/oauth/authorize?client_id=%@&redirect_uri=urn%%3Aietf%%3Awg%%3Aoauth%%3A2.0%%3Aoob&response_type=code",INatBaseURL,INatClientID ]];
    [[NXOAuth2AccountStore sharedStore] setClientID:INatClientID
                                             secret:INatClientSecret
                                   authorizationURL:authorizationURL
                                           tokenURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/oauth/token", INatBaseURL]]
                                        redirectURL:[NSURL URLWithString:@"urn:ietf:wg:oauth:2.0:oob"]
                                     forAccountType:kINatAuthService];
    
    for (NXOAuth2Account *account in [sharedStore accountsWithAccountType:kINatAuthServiceExtToken]) {
        // Do something with the account
        [[NXOAuth2AccountStore sharedStore] removeAccount:account];
    };
    [[NXOAuth2AccountStore sharedStore] setClientID:INatClientID
                                             secret:INatClientSecret
                                   authorizationURL:authorizationURL
                                           tokenURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/oauth/assertion_token.json", INatBaseURL]]
                                        redirectURL:[NSURL URLWithString:@"urn:ietf:wg:oauth:2.0:oob"]
                                     forAccountType:kINatAuthServiceExtToken];
}

- (BOOL)loggedIn
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *username = [defaults objectForKey:INatUsernamePrefKey];
    //return (username && username.length > 0);
    NSString *inatToken = [defaults objectForKey:INatTokenPrefKey];
    return ((username && username.length > 0) || (inatToken && inatToken.length > 0));
}

@end
