//
//  ExploreSearchPredicate.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/5/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreSearchPredicate.h"
#import "ExploreLocation.h"
#import "ExploreProject.h"
#import "ExplorePerson.h"
#import "Taxon.h"

@implementation ExploreSearchPredicate

- (NSString *)colloquialSearchPhrase {
    switch (self.type) {
        case ExploreSearchPredicateTypeCritter:
            if (self.searchTaxon.defaultName) {
                return [NSString stringWithFormat:@"named '%@ (%@)'", self.searchTaxon.name, self.searchTaxon.defaultName];
            } else {
                return [NSString stringWithFormat:@"named '%@'", self.searchTaxon.name];
            }
            break;
        case ExploreSearchPredicateTypePeople:
            if (self.searchPerson.name)
                return [NSString stringWithFormat:@"seen by '%@'", self.searchPerson.name];
            else
                return [NSString stringWithFormat:@"seen by '%@'", self.searchPerson.login];
            break;
        case ExploreSearchPredicateTypeLocation:
            return [NSString stringWithFormat:@"seen at '%@'", self.searchLocation.name];
            break;
        case ExploreSearchPredicateTypeProject:
            return [NSString stringWithFormat:@"in project '%@'", self.searchProject.title];
            break;

        default:
            break;
    }
}

@end
