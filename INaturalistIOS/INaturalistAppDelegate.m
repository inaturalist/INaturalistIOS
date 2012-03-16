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
#import "ObservationPhoto.h"
#import "Project.h"
#import "ProjectObservation.h"
#import "ProjectUser.h"
#import "NSString+Inflections.h"

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
    
    NSArray *models = [NSArray arrayWithObjects:
                       List.class,
                       ListedTaxon.class,
                       Observation.class, 
                       ObservationPhoto.class, 
                       Project.class, 
                       ProjectObservation.class, 
                       ProjectUser.class, 
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
    RKLogConfigureByName("RestKit/Network", RKLogLevelTrace);
    // END DEBUG
    
    [RKObjectManager setSharedManager:manager];
}

@end
