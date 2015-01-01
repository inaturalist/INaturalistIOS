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
            if (self.searchTaxon.defaultName && ![self.searchTaxon.defaultName isEqualToString:@""]) {
                return [NSString stringWithFormat:NSLocalizedString(@"named '%@ (%@)'", nil), self.searchTaxon.name, self.searchTaxon.defaultName];
            } else {
                return [NSString stringWithFormat:NSLocalizedString(@"named '%@'", nil), self.searchTaxon.name];
            }
            break;
        case ExploreSearchPredicateTypePerson:
            if (self.searchPerson.name && ![self.searchPerson.name isEqualToString:@""])
                return [NSString stringWithFormat:NSLocalizedString(@"seen by '%@'", nil), self.searchPerson.name];
            else
                return [NSString stringWithFormat:NSLocalizedString(@"seen by '%@'", nil), self.searchPerson.login];
            break;
        case ExploreSearchPredicateTypeLocation:
            return [NSString stringWithFormat:NSLocalizedString(@"seen at '%@'", nil), self.searchLocation.name];
            break;
        case ExploreSearchPredicateTypeProject:
            return [NSString stringWithFormat:NSLocalizedString(@"in project '%@'", nil), self.searchProject.title];
            break;
        default:
            break;
    }
}

+ (instancetype)predicateForTaxon:(Taxon *)taxon {
    ExploreSearchPredicate *predicate = [[ExploreSearchPredicate alloc] init];
    predicate.type = ExploreSearchPredicateTypeCritter;
    predicate.searchTaxon = taxon;
    return predicate;
}

+ (instancetype)predicateForLocation:(ExploreLocation *)location {
    ExploreSearchPredicate *predicate = [[ExploreSearchPredicate alloc] init];
    predicate.type = ExploreSearchPredicateTypeLocation;
    predicate.searchLocation = location;
    return predicate;
}

+ (instancetype)predicateForProject:(ExploreProject *)project {
    ExploreSearchPredicate *predicate = [[ExploreSearchPredicate alloc] init];
    predicate.type = ExploreSearchPredicateTypeProject;
    predicate.searchProject = project;
    return predicate;
}

+ (instancetype)predicateForPerson:(ExplorePerson *)person {
    ExploreSearchPredicate *predicate = [[ExploreSearchPredicate alloc] init];
    predicate.type = ExploreSearchPredicateTypePerson;
    predicate.searchPerson = person;
    return predicate;
}


@end
