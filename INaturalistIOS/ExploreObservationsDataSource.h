//
//  ExploreObservationsDataSource.h
//  Explore Prototype
//
//  Created by Alex Shepard on 10/3/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <RestKit/RestKit.h>

#import "ExploreSearchPredicate.h"
#import "ExploreRegion.h"

typedef NS_ENUM(NSInteger, ExploreLeaderboardSpan) {
    ExploreLeaderboardSpanMonth,
    ExploreLeaderboardSpanYear
};

/**
 A class that implements this protocol wishes to receive notifications about
 the success and/or failure of observation fetch requests.
 */
@protocol ExploreObsNotificationDelegate
/**
 Delegate callback method that is called when an observation fetch starts.
 */
- (void)startedObservationFetch;
/**
 Delegate callback method that is called when an observation fetch finishes.
 */
- (void)finishedObservationFetch;
/**
 Delegate callback that is called when an observation fetch fails.
 @param error The network or other error.
 */
- (void)failedObservationFetch:(NSError *)error;
@end

typedef void(^FetchCompletionHandler)(NSArray *results, NSError *error);
typedef void(^PostCompletionHandler)(RKResponse *response, NSError *error);


@class ExploreObservation;

@protocol ExploreObservationsDataSource <NSObject>

@property NSOrderedSet *observations;
@property (readonly) NSArray *mappableObservations;
@property (readonly) NSArray *observationsWithPhotos;
@property NSArray *activeSearchPredicates;
@property ExploreRegion *limitingRegion;

@property (assign) id <ExploreObsNotificationDelegate> notificationDelegate;
@property (readonly) BOOL isFetching;

- (void)addSearchPredicate:(ExploreSearchPredicate *)predicate;
- (void)removeSearchPredicate:(ExploreSearchPredicate *)predicate;
- (void)removeAllSearchPredicates;
- (void)removeAllSearchPredicatesUpdatingObservations:(BOOL)update;
- (void)reload;

- (NSString *)combinedColloquialSearchPhrase;
- (BOOL)activeSearchLimitedBySearchedLocation;
- (BOOL)activeSearchLimitedByCurrentMapRegion;
- (void)expandActiveSearchToNextPageOfResults;

- (void)loadLeaderboardCompletion:(FetchCompletionHandler)handler;

@end
