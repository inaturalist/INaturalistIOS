//
//  Analytics.h
//  iNaturalist
//
//  Created by Alex Shepard on 10/7/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Analytics : NSObject

+ (Analytics *)sharedClient;

- (void)event:(NSString *)name;
- (void)event:(NSString *)name withProperties:(NSDictionary *)properties;
- (void)logAllPageViewForTarget:(UIViewController *)target;

@end

#pragma mark Event Names For Analytics

extern NSString *kAnalyticsEventAppLaunch;
