//
//  ExploreObservationsController.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/3/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <BlocksKit/BlocksKit.h>

#import "ExploreObservationsController.h"
#import "ExploreMappingProvider.h"
#import "ExploreObservation.h"
#import "ExploreLocation.h"
#import "ExploreProject.h"
#import "ExplorePerson.h"

@interface ExploreObservationsController () {
    NSMutableArray *_activeSearchPredicates;
}

@end

@implementation ExploreObservationsController

@synthesize observations;

- (instancetype)init {
    if (self = [super init]) {
        _activeSearchPredicates = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)reload {
    [self fetchObservations];
}

- (void)addSearchPredicate:(ExploreSearchPredicate *)predicate {
    // only one predicate of a type can be active at a time
    
    // if we already have an active predicate of the type to be added, remove it
    NSArray *selected = [_activeSearchPredicates bk_select:^BOOL(ExploreSearchPredicate *p) {
        return p.type != predicate.type;
    }];
    // add our new predicate to the active group
    _activeSearchPredicates = [[selected arrayByAddingObject:predicate] mutableCopy];
    
    [self fetchObservations];
}

- (void)removeSearchPredicate:(ExploreSearchPredicate *)predicate {
    [_activeSearchPredicates removeObject:predicate];
    [self fetchObservations];
}

- (void)removeAllSearchPredicates {
    [_activeSearchPredicates removeAllObjects];
    [self fetchObservations];
}

- (NSArray *)activeSearchPredicates {
    return _activeSearchPredicates;
}

- (void)fetchObservations {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    RKObjectMapping *mapping = [ExploreMappingProvider observationMapping];

    NSString *baseURL = @"http://www.inaturalist.org/observations.json";
    NSString *pathPattern = @"/observations.json";
    // for iOS, we treat "mappable" as "exploreable"
    NSString *query = @"?per_page=100&mappable=true";

    // apply active search predicates to the query
    if (_activeSearchPredicates.count > 0) {
        [SVProgressHUD showWithStatus:@"Searching for observations..." maskType:SVProgressHUDMaskTypeGradient];
        
        for (ExploreSearchPredicate *predicate in _activeSearchPredicates) {
            // TODO: not TOTALLY URL safe but it's a start...
            NSString *urlSafeSearchTerm = [predicate.searchTerm stringByReplacingOccurrencesOfString:@" " withString:@"+"];
            if (![predicate.searchTerm isEqualToString:@""]) {
                if (predicate.type == ExploreSearchPredicateTypePeople) {
                    // people search requires a differnt baseurl and thus different path pattern
                    baseURL = [NSString stringWithFormat:@"http://www.inaturalist.org/observations/%@.json", predicate.searchPerson.login];
                    pathPattern = [NSString stringWithFormat:@"/observations/%@.json", predicate.searchPerson.login];
                } else if (predicate.type == ExploreSearchPredicateTypeCritter) {
                    query = [query stringByAppendingString:[NSString stringWithFormat:@"&q=%@", urlSafeSearchTerm]];
                } else if (predicate.type == ExploreSearchPredicateTypePlace) {
                    query = [query stringByAppendingString:[NSString stringWithFormat:@"&place_id=%ld", (long)predicate.searchLocation.locationId]];
                } else if (predicate.type == ExploreSearchPredicateTypeProject) {
                    query = [query stringByAppendingString:[NSString stringWithFormat:@"&projects[]=%ld", (long)predicate.searchProject.projectId]];
                }
            }
        }
        
    } else
        [SVProgressHUD showWithStatus:@"Fetching all recent observations..." maskType:SVProgressHUDMaskTypeGradient];
    
    NSString *path = [NSString stringWithFormat:@"%@%@", pathPattern, query];
    RKObjectLoader *objectLoader = [[RKObjectManager sharedManager] objectLoaderWithResourcePath:path delegate:self];
    objectLoader.method = RKRequestMethodGET;
    objectLoader.objectMapping = mapping;
    
    objectLoader.onDidLoadObjects = ^(NSArray *array) {
        self.observations = [array copy];
        
        if (array.count > 0)
            [SVProgressHUD showSuccessWithStatus:@"Yay!"];
        else
            [SVProgressHUD showErrorWithStatus:@"No observations found."];
    };
    
    objectLoader.onDidFailWithError = ^(NSError *err) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [SVProgressHUD showErrorWithStatus:err.localizedDescription];
    };
    
    objectLoader.onDidFailLoadWithError = ^(NSError *err) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [SVProgressHUD showErrorWithStatus:err.localizedDescription];
    };
    
    [objectLoader send];
}
     

- (NSString *)combinedColloquialSearchPhrase {
    NSMutableString *colloquial = [[NSMutableString alloc] init];
    
    for (ExploreSearchPredicate *predicate in self.activeSearchPredicates) {
        if ([self.activeSearchPredicates indexOfObject:predicate] == 0)
            [colloquial appendString:predicate.colloquialSearchPhrase];
        else
            [colloquial appendFormat:@" and %@", predicate.colloquialSearchPhrase];
    }
    return colloquial;
}

- (BOOL)activeSearchLimitedByLocation {
    return [self.activeSearchPredicates bk_any:^BOOL(ExploreSearchPredicate *predicate) {
        return predicate.type == ExploreSearchPredicateTypePlace || predicate.type == ExploreSearchPredicateTypeProject;
    }];
}

- (NSArray *)mappableObservations {
    return [self.observations bk_select:^BOOL(ExploreObservation *observation) {
        // for iOS, we have our own idea of what "mappable" is
        return !observation.coordinatesObscured;
    }];
}

@end
