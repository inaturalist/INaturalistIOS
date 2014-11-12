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
    NSInteger lastPagedFetched;
    ExploreRegion *_limitingRegion;
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
    [self fetchObservationsShouldNotify:YES];
}

- (void)setLimitingRegion:(ExploreRegion *)newRegion {
    if ([_limitingRegion isEqualToRegion:newRegion])
        return;
    
    _limitingRegion = newRegion;
    
    // trim out any observations that aren't in the map rect, unless we have an overriding location search predicate
    if (![self hasActiveLocationSearchPredicate]) {
        self.observations = [self.observations bk_select:^BOOL(id <MKAnnotation> annotation) {
            return MKMapRectContainsPoint(_limitingRegion.mapRect, MKMapPointForCoordinate(annotation.coordinate));
        }];
    }

    [self fetchObservationsShouldNotify:YES];
}

-(ExploreRegion *)limitingRegion {
    return _limitingRegion;
}

- (void)addSearchPredicate:(ExploreSearchPredicate *)newPredicate {
    lastPagedFetched = 1;
    
    // clear any stashed objects
    self.observations = [NSOrderedSet orderedSet];
    
    // if we already have an active predicate of the type to be added, remove it
    NSArray *selected = [self.activeSearchPredicates bk_select:^BOOL(ExploreSearchPredicate *p) {
        return p.type != newPredicate.type;
    }];

    // add our new predicate to the active group
    self.activeSearchPredicates = [selected arrayByAddingObject:newPredicate];
    
    // fetch using new search predicate(s)
    [self fetchObservationsShouldNotify:YES];
}


- (void)removeSearchPredicate:(ExploreSearchPredicate *)predicate {
    lastPagedFetched = 1;

    NSMutableArray *predicates = [self.activeSearchPredicates mutableCopy];
    [predicates removeObject:predicate];
    self.activeSearchPredicates = predicates;
    
    // clear any stashed objects
    self.observations = [NSOrderedSet orderedSet];
    
    // fetch using new search predicate(s), if any
    [self fetchObservationsShouldNotify:YES];
}

- (void)removeAllSearchPredicates {
    [self removeAllSearchPredicatesUpdatingObservations:YES];
}

- (void)removeAllSearchPredicatesUpdatingObservations:(BOOL)update {
    lastPagedFetched = 1;
    
    self.activeSearchPredicates = @[];
    
    // clear any stashed objects
    self.observations = [NSOrderedSet orderedSet];
    
    if (update)
        [self fetchObservationsShouldNotify:YES];
}

- (void)expandActiveSearchToNextPageOfResults {
    [self fetchObservationsPage:++lastPagedFetched];
}

- (void)fetchObservationsPage:(NSInteger)page {
    NSString *path = [self pathForFetchWithSearchPredicates:self.activeSearchPredicates
                                                   withPage:page];
    [self performObservationFetchForPath:path shouldNotify:YES];
}

- (void)fetchObservationsShouldNotify:(BOOL)notify {
    NSString *path = [self pathForFetchWithSearchPredicates:self.activeSearchPredicates];
    [self performObservationFetchForPath:path shouldNotify:notify];
}

- (NSString *)pathForFetchWithSearchPredicates:(NSArray *)predicates withPage:(NSInteger)page {
    NSString *path = [self pathForFetchWithSearchPredicates:predicates];
    return [path stringByAppendingString:[NSString stringWithFormat:@"&page=%ld", (long)page]];
}

- (NSString *)pathForFetchWithSearchPredicates:(NSArray *)predicates {
    NSString *baseURL = @"http://www.inaturalist.org/observations.json";
    NSString *pathPattern = @"/observations.json";
    // for iOS, we treat "mappable" as "exploreable"
    NSString *query = @"?per_page=100&mappable=true";
    
    BOOL hasActiveLocationPredicate = NO;
    
    // apply active search predicates to the query
    if (predicates.count > 0) {
        for (ExploreSearchPredicate *predicate in predicates) {
            if (predicate.type == ExploreSearchPredicateTypePerson) {
                // people search requires a differnt baseurl and thus different path pattern
                baseURL = [NSString stringWithFormat:@"http://www.inaturalist.org/observations/%@.json", predicate.searchPerson.login];
                pathPattern = [NSString stringWithFormat:@"/observations/%@.json", predicate.searchPerson.login];
            } else if (predicate.type == ExploreSearchPredicateTypeCritter) {
                query = [query stringByAppendingString:[NSString stringWithFormat:@"&taxon_id=%ld", (long)predicate.searchTaxon.recordID.integerValue]];
            } else if (predicate.type == ExploreSearchPredicateTypeLocation) {
                hasActiveLocationPredicate = YES;
                query = [query stringByAppendingString:[NSString stringWithFormat:@"&place_id=%ld", (long)predicate.searchLocation.locationId]];
            } else if (predicate.type == ExploreSearchPredicateTypeProject) {
                query = [query stringByAppendingString:[NSString stringWithFormat:@"&projects[]=%ld", (long)predicate.searchProject.projectId]];
            }
        }
    }
    
    // having a Location predicate cancels any limiting region boundary
    if (self.limitingRegion && !hasActiveLocationPredicate) {
        query = [query stringByAppendingString:[NSString stringWithFormat:@"&swlat=%f&swlng=%f&nelat=%f&nelng=%f",
                                                self.limitingRegion.swCoord.latitude,
                                                self.limitingRegion.swCoord.longitude,
                                                self.limitingRegion.neCoord.latitude,
                                                self.limitingRegion.neCoord.longitude]];
    }

    
    return [NSString stringWithFormat:@"%@%@", pathPattern, query];
}

- (void)performObservationFetchForPath:(NSString *)path shouldNotify:(BOOL)shouldNotify {
    
    if (shouldNotify) {
        NSString *statusMessage;
        if (self.activeSearchPredicates.count > 0) {
            // searching
            if (self.limitingRegion)
                statusMessage = @"Searching for recent observations in map area";
            else
                statusMessage = @"Searching for recent observations worldwide";
        } else {
            if (self.limitingRegion)
                statusMessage = @"Fetching recent observations in map area";
            else
                statusMessage = @"Fetching recent observations worldwide";
        }

        [SVProgressHUD showWithStatus:statusMessage maskType:SVProgressHUDMaskTypeGradient];
    }
    
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:path usingBlock:^(RKObjectLoader *loader) {
        
        // can't infer search mappings via keypath
        loader.objectMapping = [ExploreMappingProvider observationMapping];
        
        loader.onDidLoadObjects = ^(NSArray *array) {
            NSSet *trimmedObservations;
            NSSet *unorderedObservations;
            if (self.limitingRegion) {
                trimmedObservations = [self.observations.set bk_select:^BOOL(ExploreObservation *obs) {
                    // trim out anything that isn't in the limiting region
                    return [self.limitingRegion containsCoordinate:obs.coordinate];
                }];
                unorderedObservations = [trimmedObservations setByAddingObjectsFromArray:array];
            } else {
                unorderedObservations = [self.observations.set setByAddingObjectsFromArray:array];
            }
            NSArray *orderedObservations = [[unorderedObservations allObjects] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                return ((ExploreObservation *)obj1).observationId < ((ExploreObservation *)obj2).observationId;
            }];
            
            self.observations = [[NSOrderedSet alloc] initWithArray:orderedObservations];
            
            if (shouldNotify) {
                if (array.count > 0)
                    [SVProgressHUD showSuccessWithStatus:@"Yay!"];
                else
                    [SVProgressHUD showErrorWithStatus:@"No observations found."];
            }
        };
        
        loader.onDidFailWithError = ^(NSError *err) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            if (shouldNotify)
                [SVProgressHUD showErrorWithStatus:err.localizedDescription];
        };
        
        loader.onDidFailLoadWithError = ^(NSError *err) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            if (shouldNotify)
                [SVProgressHUD showErrorWithStatus:err.localizedDescription];
        };
    }];
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

- (BOOL)activeSearchLimitedByCurrentMapRegion {
    return self.limitingRegion && ![self hasActiveLocationSearchPredicate];
}

- (BOOL)activeSearchLimitedBySearchedLocation {
    return [self.activeSearchPredicates bk_any:^BOOL(ExploreSearchPredicate *predicate) {
        return predicate.type == ExploreSearchPredicateTypeLocation || predicate.type == ExploreSearchPredicateTypeProject;
    }];
}

- (NSArray *)mappableObservations {
    return [self.observations.array bk_select:^BOOL(ExploreObservation *observation) {
        // for iOS, we have our own idea of what "mappable" is
        return !observation.coordinatesObscured;
    }];
}

- (BOOL)hasActiveLocationSearchPredicate {
    return [self.activeSearchPredicates bk_any:^BOOL(ExploreSearchPredicate *p) {
        return p.type == ExploreSearchPredicateTypeLocation;
    }];
}

@end
