//
//  INatObserverAppDelegate.m
//  INatObserver
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "INatObserverAppDelegate.h"
#import "Observation.h"

@implementation INatObserverAppDelegate

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
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

@end
