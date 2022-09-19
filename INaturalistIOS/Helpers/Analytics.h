//
//  Analytics.h
//  iNaturalist
//
//  Created by Alex Shepard on 10/7/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Analytics : NSObject

+ (BOOL)canTrack;

+ (void)disableCrashReporting;
+ (void)enableCrashReporting;

+ (Analytics *)sharedClient;

- (void)event:(NSString *)name;
- (void)event:(NSString *)name withProperties:(NSDictionary *)properties;

- (void)debugLog:(NSString *)logMessage;
- (void)debugError:(NSError *)error;

- (void)logMetric:(NSString *)metricName value:(NSNumber *)metricValue;

@end
