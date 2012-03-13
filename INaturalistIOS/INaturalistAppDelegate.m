//
//  INaturalistAppDelegate.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "INaturalistAppDelegate.h"
#import "Observation.h"
#import "ObservationPhoto.h"

@implementation INaturalistAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [self configureRestKit];
    
    return YES;
}

- (void)configureRestKit
{
    RKObjectManager* manager = [RKObjectManager objectManagerWithBaseURL:INatBaseURL];
    manager.objectStore = [RKManagedObjectStore objectStoreWithStoreFilename:@"inaturalist.sqlite"];
    
    // Routes
    [manager.router routeClass:[Observation class] toResourcePath:@"/observations/:recordID"];
    [manager.router routeClass:[Observation class] toResourcePath:@"/observations" forMethod:RKRequestMethodPOST];
    [manager.router routeClass:[ObservationPhoto class] toResourcePath:@"/observation_photos/:recordID"];
    [manager.router routeClass:[ObservationPhoto class] toResourcePath:@"/observation_photos" forMethod:RKRequestMethodPOST];
    
    // Auth
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [RKClient.sharedClient setUsername:[defaults objectForKey:INatUsernamePrefKey]];
    [RKClient.sharedClient setPassword:[defaults objectForKey:INatPasswordPrefKey]];
    
    // User Agent
    UIDevice *d = [UIDevice currentDevice];
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [RKClient.sharedClient setValue:[NSString stringWithFormat:@"iNaturalist/%@ (iOS %@ %@ %@)", 
                                     appVersion,
                                     d.systemName, 
                                     d.systemVersion, 
                                     d.model] 
                 forHTTPHeaderField:@"User-Agent"];
    
    // Serialization
    [manager.mappingProvider setSerializationMapping:[Observation serializationMapping] forClass:[Observation class]];
    [manager.mappingProvider setObjectMapping:[Observation mapping] forKeyPath:@"observation"];
    [manager.mappingProvider setSerializationMapping:[ObservationPhoto serializationMapping] forClass:[ObservationPhoto class]];
    [manager.mappingProvider setObjectMapping:[ObservationPhoto mapping] forKeyPath:@"observation_photo"];
    
    // Make sure RK knows how to parse simple dates
    NSDateFormatter* dateFormatter = [NSDateFormatter new];
    [dateFormatter  setDateFormat:@"yyyy-MM-dd"];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    dateFormatter.locale = [NSLocale currentLocale];
    [RKObjectMapping addDefaultDateFormatter:dateFormatter];
    
    [[[RKObjectManager sharedManager] client] requestQueue].showsNetworkActivityIndicatorWhenBusy = YES;
    
    // DEBUG
//    RKLogConfigureByName("RestKit/Network", RKLogLevelTrace);
    // END DEBUG
    
    [RKObjectManager setSharedManager:manager];
}

@end
