//
//  Analytics.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/7/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

@import Firebase;
@import FirebaseAnalytics;
@import FirebaseCrashlytics;

#import "Analytics.h"

@interface Analytics ()
@end

@implementation Analytics

+ (BOOL)canTrack {
    // firebase analytics stuff (even checking for it) crashes on ios 12
    if (@available(iOS 13.0, *)) {
        NSString *path = [[NSBundle mainBundle] pathForResource: @"GoogleService-Info"
                                                         ofType: @"plist"];
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: path];
        NSString *googleAppId = [[dict objectForKey: @"GOOGLE_APP_ID"] stringValue];
        if (!googleAppId || [googleAppId isEqualToString:@"Google-App-Id-Placeholder"]) {
            return NO;
        }

        BOOL prefersNoTrack = [[NSUserDefaults standardUserDefaults] boolForKey:kINatPreferNoTrackPrefKey];
        if (prefersNoTrack) {
            return NO;
        } else {
            return YES;
        }
    } else {
        return NO;
    }
}

+ (void)disableCrashReporting {
    [[FIRCrashlytics crashlytics] setCrashlyticsCollectionEnabled:NO];
}

+ (void)enableCrashReporting {
    [[FIRCrashlytics crashlytics] setCrashlyticsCollectionEnabled:YES];
}

+ (Analytics *)sharedClient {
    static Analytics *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[Analytics alloc] init];
        if ([Analytics canTrack]) {
            if (![FIRApp defaultApp]) {
                [FIRApp configure];
            }
            [[FIRCrashlytics crashlytics] setCrashlyticsCollectionEnabled:YES];
        }
    });
    return _sharedClient;
}

- (void)logMetric:(NSString *)metricName value:(NSNumber *)metricValue {
    if ([Analytics canTrack]) {
        [self event:metricName withProperties:@{ @"Amount": metricValue }];
    }
}

- (void)event:(NSString *)name {
    if ([Analytics canTrack] && [FIRApp defaultApp]) {
        [FIRAnalytics logEventWithName:name parameters:nil];
    }
}

- (void)event:(NSString *)name withProperties:(NSDictionary *)properties {
    if ([Analytics canTrack] && [FIRApp defaultApp]) {
        [FIRAnalytics logEventWithName:name parameters:properties];
    }
}

- (void)debugLog:(NSString *)logMessage {
    if ([Analytics canTrack] && [FIRApp defaultApp]) {
        [[FIRCrashlytics crashlytics] log:logMessage];
    }
}

- (void)debugError:(NSError *)error {
    if ([Analytics canTrack] && [FIRApp defaultApp]) {
        [[FIRCrashlytics crashlytics] recordError:error];
    }
}

@end
