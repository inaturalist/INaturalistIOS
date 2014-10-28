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

- (void)timedEvent:(NSString *)name {
    [Flurry logEvent:name timed:YES];
}
- (void)timedEvent:(NSString *)name withProperties:(NSDictionary *)properties {
    [Flurry logEvent:name withParameters:properties timed:YES];
}

- (void)endTimedEvent:(NSString *)name {
    [Flurry endTimedEvent:name withParameters:nil];
}
- (void)endTimedEvent:(NSString *)name withProperties:(NSDictionary *)properties {
    [Flurry endTimedEvent:name withParameters:properties];
}


@end


#pragma mark Event Names For Analytics

NSString *kAnalyticsEventAppLaunch = @"AppLaunch";

// navigation
NSString *kAnalyticsEventNavigateExploreGrid =                  @"Explore - Navigate - Grid";
NSString *kAnalyticsEventNavigateExploreMap =                   @"Explore - Navigate - Map";
NSString *kAnalyticsEventNavigateExploreList =                  @"Explore - Navigate - List";
NSString *kAnalyticsEventNavigateExploreObsDetails =            @"Explore - Navigate - Obs Details";
NSString *kAnalyticsEventNavigateExploreTaxonDetails =          @"Explore - Navigate - Taxon Details";

// search in explore
NSString *kAnalyticsEventExploreSearchPeople =                  @"Explore - Search - People";
NSString *kAnalyticsEventExploreSearchProjects =                @"Explore - Search - Projects";
NSString *kAnalyticsEventExploreSearchPlaces =                  @"Explore - Search - Places";
NSString *kAnalyticsEventExploreSearchCritters =                @"Explore - Search - Critters";
NSString *kAnalyticsEventExploreSearchNearMe =                  @"Explore - Search - Near Me";


// add comments & ids in explore
NSString *kAnalyticsEventExploreAddComment =                    @"Explore - Add Comment";
NSString *kAnalyticsEventExploreAddIdentification =             @"Explore - Add Identification";

// share in explore
NSString *kAnalyticsEventExploreObservationShare =              @"Explore - Observation - Share";

// create observation
NSString *kAnalyticsEventCreateObservation =                    @"Create Observation";
NSString *kAnalyticsEventSyncObservation =                      @"Sync Observation";

// login
NSString *kAnalyticsEventLogin =                                @"Login";
NSString *kAnalyticsEventSignup =                               @"Create Account";


