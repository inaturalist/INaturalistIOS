//
//  Analytics.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/7/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <FlurrySDK/Flurry.h>
#import <Crashlytics/Crashlytics.h>

#import "Analytics.h"

@interface Analytics () <CrashlyticsDelegate> {
    
}
@end

@implementation Analytics

// without a flurry key, event logging is a no-op
+ (Analytics *)sharedClient {
    static Analytics *_sharedClient = nil;
#ifdef INatFlurryKey
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[Analytics alloc] init];
        [Flurry startSession:INatFlurryKey];
        
#ifdef INatCrashlyticsKey
        [Crashlytics startWithAPIKey:INatCrashlyticsKey];
#endif

    });
#endif
    return _sharedClient;
}

- (void)event:(NSString *)name {
    [Flurry logEvent:name];
}

- (void)event:(NSString *)name withProperties:(NSDictionary *)properties {
    [Flurry logEvent:name withParameters:properties];
}

- (void)logAllPageViewForTarget:(UIViewController *)target {
    [Flurry logAllPageViewsForTarget:target];
}

@end


#pragma mark Event Names For Analytics

NSString *kAnalyticsEventAppLaunch = @"AppLaunch";
