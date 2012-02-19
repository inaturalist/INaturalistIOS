//
//  INaturalistIOSAppDelegate.m
//  INaturalistIOS
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "INaturalistIOSAppDelegate.h"
#import "Observation.h"

@implementation INaturalistIOSAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    RKObjectManager* manager = [RKObjectManager objectManagerWithBaseURL:@"http://localhost:3000"];
    manager.objectStore = [RKManagedObjectStore objectStoreWithStoreFilename:@"inaturalist.sqlite"];
    [manager.router routeClass:[Observation class] toResourcePath:@"/observations/:recordID"];
    [manager.router routeClass:[Observation class] toResourcePath:@"/observations" forMethod:RKRequestMethodPOST];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [RKClient.sharedClient setUsername:[defaults objectForKey:INatUsernamePrefKey]];
    [RKClient.sharedClient setPassword:[defaults objectForKey:INatPasswordPrefKey]];
    [RKClient.sharedClient setValue:@"iNaturalist/2.0.0 (iOS OS_VERSION DEVICE_NAME DEVICE_VERSION)" 
                 forHTTPHeaderField:@"User-Agent"];
    
    [manager.mappingProvider setSerializationMapping:[Observation serializationMapping] forClass:[Observation class]];
    [manager.mappingProvider setObjectMapping:[Observation mapping] forKeyPath:@"observation"];
    
    // DEBUG
//    RKLogConfigureByName("RestKit/Network", RKLogLevelTrace);
    // END DEBUG
     
    [RKObjectManager setSharedManager:manager];
    
    return YES;
}

@end
