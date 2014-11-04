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
#import "Taxon.h"

@interface ExploreObservationsController () {
    BOOL _latestSearchShouldResetUI;
    NSInteger lastPagedFetched;
}
@end

@implementation ExploreObservationsController

@synthesize observations, activeSearchPredicates;

- (instancetype)init {
    if (self = [super init]) {
        self.activeSearchPredicates = @[];
        self.observations = [NSOrderedSet orderedSet];
        lastPagedFetched = 1;
    }
    return self;
}

- (void)reload {
    [self fetchObservations];
}

- (void)addSearchPredicate:(ExploreSearchPredicate *)predicate {
    lastPagedFetched = 1;
    
    // clear any stashed objects
    self.observations = [NSOrderedSet orderedSet];

    // only one predicate of a type can be active at a time
    
    // if we already have an active predicate of the type to be added, remove it
    NSArray *selected = [self.activeSearchPredicates bk_select:^BOOL(ExploreSearchPredicate *p) {
        return p.type != predicate.type;
    }];
    // add our new predicate to the active group
    self.activeSearchPredicates = [selected arrayByAddingObject:predicate];
    
    // fetch using new search predicate(s)
    [self fetchObservations];
}

- (void)removeSearchPredicate:(ExploreSearchPredicate *)predicate {
    lastPagedFetched = 1;

    NSMutableArray *predicates = [self.activeSearchPredicates mutableCopy];
    [predicates removeObject:predicate];
    self.activeSearchPredicates = predicates;
    
    // clear any stashed objects
    self.observations = [NSOrderedSet orderedSet];
    
    // fetch using new search predicate(s), if any
    [self fetchObservations];
}

- (void)removeAllSearchPredicates {
    lastPagedFetched = 1;
    
    self.activeSearchPredicates = @[];
    
    // clear any stashed objects
    self.observations = [NSOrderedSet orderedSet];
    
    // fetch using no search predicates
    [self fetchObservations];
}

- (void)expandActiveSearchIntoLocationRegion:(ExploreRegion *)region {
    [self fetchObservationsInLocationRegion:region];
}

- (void)expandActiveSearchToNextPageOfResults {
    [self fetchObservationsPage:++lastPagedFetched];
}

- (void)fetchObservationsInLocationRegion:(ExploreRegion *)region {
    NSString *path = [self pathForFetchWithSearchPredicates:self.activeSearchPredicates
                                           inLocationRegion:region];
    [self performObservationFetchForPath:path shouldNotify:NO shouldResetUI:NO];
}

- (void)fetchObservationsPage:(NSInteger)page {
    NSString *path = [self pathForFetchWithSearchPredicates:self.activeSearchPredicates
                                                   withPage:page];
    [self performObservationFetchForPath:path shouldNotify:YES shouldResetUI:NO];
}

- (void)fetchObservations {
    NSString *path = [self pathForFetchWithSearchPredicates:self.activeSearchPredicates];
    [self performObservationFetchForPath:path shouldNotify:YES shouldResetUI:YES];
}

- (NSString *)pathForFetchWithSearchPredicates:(NSArray *)predicates {
    return [self pathForFetchWithSearchPredicates:predicates inLocationRegion:nil];
}

- (NSString *)pathForFetchWithSearchPredicates:(NSArray *)predicates withPage:(NSInteger)page {
    NSString *path = [self pathForFetchWithSearchPredicates:predicates inLocationRegion:nil];
    return [path stringByAppendingString:[NSString stringWithFormat:@"&page=%ld", (long)page]];
}

- (NSString *)pathForFetchWithSearchPredicates:(NSArray *)predicates inLocationRegion:(ExploreRegion *)region {
    NSString *baseURL = @"http://www.inaturalist.org/observations.json";
    NSString *pathPattern = @"/observations.json";
    // for iOS, we treat "mappable" as "exploreable"
    NSString *query = @"?per_page=100&mappable=true";
    
    if (region) {
        query = [query stringByAppendingString:[NSString stringWithFormat:@"&swlat=%f&swlng=%f&nelat=%f&nelng=%f",
                                                region.swCoord.latitude, region.swCoord.longitude,
                                                region.neCoord.latitude, region.neCoord.longitude]];
    }
    
    // apply active search predicates to the query
    if (predicates.count > 0) {
        for (ExploreSearchPredicate *predicate in predicates) {
            if (predicate.type == ExploreSearchPredicateTypePeople) {
                // people search requires a differnt baseurl and thus different path pattern
                baseURL = [NSString stringWithFormat:@"http://www.inaturalist.org/observations/%@.json", predicate.searchPerson.login];
                pathPattern = [NSString stringWithFormat:@"/observations/%@.json", predicate.searchPerson.login];
            } else if (predicate.type == ExploreSearchPredicateTypeCritter) {
                query = [query stringByAppendingString:[NSString stringWithFormat:@"&taxon_id=%ld", (long)predicate.searchTaxon.recordID.integerValue]];
            } else if (predicate.type == ExploreSearchPredicateTypePlace) {
                query = [query stringByAppendingString:[NSString stringWithFormat:@"&place_id=%ld", (long)predicate.searchLocation.locationId]];
            } else if (predicate.type == ExploreSearchPredicateTypeProject) {
                query = [query stringByAppendingString:[NSString stringWithFormat:@"&projects[]=%ld", (long)predicate.searchProject.projectId]];
            }
        }
    }
    
    return [NSString stringWithFormat:@"%@%@", pathPattern, query];
}

- (void)performObservationFetchForPath:(NSString *)path shouldNotify:(BOOL)shouldNotify shouldResetUI:(BOOL)shouldResetUI {
    
    if (shouldNotify) {
        if (self.activeSearchPredicates.count > 0)
            [SVProgressHUD showWithStatus:@"Searching for observations..." maskType:SVProgressHUDMaskTypeGradient];
        else
            [SVProgressHUD showWithStatus:@"Fetching all recent observations..." maskType:SVProgressHUDMaskTypeGradient];
    }
    
    RKObjectMapping *mapping = [ExploreMappingProvider observationMapping];
    RKObjectLoader *objectLoader = [[RKObjectManager sharedManager] objectLoaderWithResourcePath:path delegate:nil];
    objectLoader.method = RKRequestMethodGET;
    objectLoader.objectMapping = mapping;
    
    objectLoader.onDidLoadObjects = ^(NSArray *array) {
        NSSet *unorderedObservations = [self.observations.set setByAddingObjectsFromArray:array];
        NSArray *orderedObservations = [[unorderedObservations allObjects] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return ((ExploreObservation *)obj1).observationId < ((ExploreObservation *)obj2).observationId;
        }];
        _latestSearchShouldResetUI = shouldResetUI;
        self.observations = [[NSOrderedSet alloc] initWithArray:orderedObservations];        
        
        if ([SVProgressHUD isVisible]) {
            if (array.count > 0)
                [SVProgressHUD showSuccessWithStatus:@"Yay!"];
            else
                [SVProgressHUD showErrorWithStatus:@"No observations found."];
        }
    };
    
    objectLoader.onDidFailWithError = ^(NSError *err) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        if (shouldNotify)
            [SVProgressHUD showErrorWithStatus:err.localizedDescription];
    };
    
    objectLoader.onDidFailLoadWithError = ^(NSError *err) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        if (shouldNotify)
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
    return [self.observations.array bk_select:^BOOL(ExploreObservation *observation) {
        // for iOS, we have our own idea of what "mappable" is
        return !observation.coordinatesObscured;
    }];
}

- (BOOL)latestSearchShouldResetUI {
    return _latestSearchShouldResetUI;
}

@end
