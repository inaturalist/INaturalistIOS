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

@protocol ExploreObservationsDataSource <NSObject>

@property NSArray *observations;
@property (readonly) NSArray *mappableObservations;

- (void)addSearchPredicate:(ExploreSearchPredicate *)predicate;
- (void)removeSearchPredicate:(ExploreSearchPredicate *)predicate;
- (void)removeAllSearchPredicates;
- (void)reload;

- (NSString *)combinedColloquialSearchPhrase;
@property (readonly) NSArray *activeSearchPredicates;
- (BOOL)activeSearchLimitedByLocation;

@end
