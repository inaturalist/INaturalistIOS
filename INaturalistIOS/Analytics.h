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

- (void)timedEvent:(NSString *)name;
- (void)timedEvent:(NSString *)name withProperties:(NSDictionary *)properties;
- (void)endTimedEvent:(NSString *)name;
- (void)endTimedEvent:(NSString *)name withProperties:(NSDictionary *)properties;

@end

#pragma mark Event Names For Analytics

extern NSString *kAnalyticsEventAppLaunch;

// navigation
extern NSString *kAnalyticsEventNavigateExploreGrid;
extern NSString *kAnalyticsEventNavigateExploreMap;
extern NSString *kAnalyticsEventNavigateExploreList;
extern NSString *kAnalyticsEventNavigateExploreObsDetails;
extern NSString *kAnalyticsEventNavigateExploreTaxonDetails;

// search in explore
extern NSString *kAnalyticsEventExploreSearchPeople;
extern NSString *kAnalyticsEventExploreSearchProjects;
extern NSString *kAnalyticsEventExploreSearchPlaces;
extern NSString *kAnalyticsEventExploreSearchCritters;

extern NSString *kAnalyticsEventExploreSearchNearMe;
extern NSString *kAnalyticsEventExploreSearchMine;


// add comments & ids in explore
extern NSString *kAnalyticsEventExploreAddComment;
extern NSString *kAnalyticsEventExploreAddIdentification;

// share in explore
extern NSString *kAnalyticsEventExploreObservationShare;

// create observation
extern NSString *kAnalyticsEventCreateObservation;
extern NSString *kAnalyticsEventSyncObservation;

// login
extern NSString *kAnalyticsEventLogin;
extern NSString *kAnalyticsEventSignup;

