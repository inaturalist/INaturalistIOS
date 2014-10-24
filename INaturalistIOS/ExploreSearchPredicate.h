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
@class ExplorePerson;

typedef NS_ENUM(NSInteger, ExploreSearchPredicateType) {
    ExploreSearchPredicateTypeCritter,
    ExploreSearchPredicateTypePeople,
    ExploreSearchPredicateTypePlace,
    ExploreSearchPredicateTypeProject
};

@interface ExploreSearchPredicate : UIViewController

@property ExploreSearchPredicateType type;
@property (copy) NSString *searchTerm;
@property (retain) ExploreLocation *searchLocation;
@property (retain) ExploreProject *searchProject;
@property (retain) ExplorePerson *searchPerson;

// for example: "Critters named 'Butterfly'", or "Persone chiamato 'alex shepard'"
@property (readonly) NSString *colloquialSearchPhrase;

@end
