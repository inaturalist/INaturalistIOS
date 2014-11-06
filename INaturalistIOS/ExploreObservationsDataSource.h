//
//  ExploreObservationsDataSource.h
//  Explore Prototype
//
//  Created by Alex Shepard on 10/3/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "ExploreSearchPredicate.h"
#import "ExploreRegion.h"

@protocol ExploreObservationsDataSource <NSObject>

@property NSOrderedSet *observations;
@property (readonly) NSArray *mappableObservations;
@property NSArray *activeSearchPredicates;
@property ExploreRegion *limitingRegion;

- (void)addSearchPredicate:(ExploreSearchPredicate *)predicate;
- (void)removeSearchPredicate:(ExploreSearchPredicate *)predicate;
- (void)removeAllSearchPredicates;
- (void)removeAllSearchPredicatesUpdatingObservations:(BOOL)update;
- (void)reload;

- (NSString *)combinedColloquialSearchPhrase;
- (BOOL)activeSearchLimitedBySearchedLocation;
- (BOOL)activeSearchLimitedByLimitingRegion;
- (void)expandActiveSearchToNextPageOfResults;

@end
