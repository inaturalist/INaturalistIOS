//
//  ExploreSearchPredicate.h
//  Explore Prototype
//
//  Created by Alex Shepard on 10/5/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ExploreLocation;
@class ExploreProject;
@class ExploreUser;
@class ExploreRegion;
@class ExploreTaxon;

typedef NS_ENUM(NSInteger, ExploreSearchPredicateType) {
    ExploreSearchPredicateTypeCritter,
    ExploreSearchPredicateTypePerson,
    ExploreSearchPredicateTypeLocation,
    ExploreSearchPredicateTypeProject
};

@interface ExploreSearchPredicate : UIViewController

@property ExploreSearchPredicateType type;
@property (retain) ExploreTaxon *searchTaxon;
@property (retain) ExploreLocation *searchLocation;
@property (retain) ExploreProject *searchProject;
@property (retain) ExploreUser *searchPerson;

// for example: "Critters named 'Butterfly'", or "Persone chiamato 'alex shepard'"
@property (readonly) NSString *colloquialSearchPhrase;
@property (readonly) NSString *searchTerm;      // for example: Butterfly

+ (instancetype)predicateForTaxon:(ExploreTaxon *)taxon;
+ (instancetype)predicateForLocation:(ExploreLocation *)location;
+ (instancetype)predicateForProject:(ExploreProject *)project;
+ (instancetype)predicateForPerson:(ExploreUser *)person;

@end
