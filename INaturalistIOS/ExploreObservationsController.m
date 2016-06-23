//
//  ExploreObservationsController.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/3/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <BlocksKit/BlocksKit.h>

#import "ExploreObservationsController.h"
#import "ExploreMappingProvider.h"
#import "ExploreObservation.h"
#import "ExploreLocation.h"
#import "ExploreProject.h"
#import "ExplorePerson.h"
#import "Taxon.h"
#import "NSURL+INaturalist.h"
#import "NSLocale+INaturalist.h"
#import "Analytics.h"
#import "INatAPI.h"
#import "ObserverCount.h"

@interface ExploreObservationsController () {
    NSInteger lastPagedFetched;
    ExploreRegion *_limitingRegion;
}
@property (readonly) INatAPI *api;
@end

@implementation ExploreObservationsController

// these come from a delegate so will not be auto synthesized
@synthesize observations, activeSearchPredicates, notificationDelegate;

- (INatAPI *)api {
	static INatAPI *_api;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
    	_api = [[INatAPI alloc] init];
    });
    return _api;
}

- (instancetype)init {
    if (self = [super init]) {
        self.activeSearchPredicates = @[];
        self.observations = [NSOrderedSet orderedSet];
        lastPagedFetched = 1;
    }
    return self;
}

- (void)reload {
    if ([[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        [self fetchObservationsShouldNotify:YES];
    } else {
        NSError *error = [NSError errorWithDomain:@"org.inaturalist"
                                             code:-1008
                                         userInfo:@{
                                                    NSLocalizedDescriptionKey: @"Network unavailable, cannot search iNaturalist.org"
                                                    }];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.notificationDelegate failedObservationFetch:error];
        });
    }
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

    if ([[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        [self fetchObservationsShouldNotify:NO];
    } else {
        NSError *error = [NSError errorWithDomain:@"org.inaturalist"
                                             code:-1008
                                         userInfo:@{
                                                    NSLocalizedDescriptionKey: @"Network unavailable, cannot search iNaturalist.org"
                                                    }];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.notificationDelegate failedObservationFetch:error];
        });
    }
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
    
    if ([[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        // fetch using new search predicate(s)
        [self fetchObservationsShouldNotify:YES];
    } else {
        NSError *error = [NSError errorWithDomain:@"org.inaturalist"
                                             code:-1008
                                         userInfo:@{
                                                    NSLocalizedDescriptionKey: @"Network unavailable, cannot search iNaturalist.org"
                                                    }];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.notificationDelegate failedObservationFetch:error];
        });
    }
}


- (void)removeSearchPredicate:(ExploreSearchPredicate *)predicate {
    lastPagedFetched = 1;

    NSMutableArray *predicates = [self.activeSearchPredicates mutableCopy];
    [predicates removeObject:predicate];
    self.activeSearchPredicates = predicates;
    
    // clear any stashed objects
    self.observations = [NSOrderedSet orderedSet];
    
    if ([[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        // fetch using new search predicate(s)
        [self fetchObservationsShouldNotify:YES];
    } else {
        NSError *error = [NSError errorWithDomain:@"org.inaturalist"
                                             code:-1008
                                         userInfo:@{
                                                    NSLocalizedDescriptionKey: @"Network unavailable, cannot search iNaturalist.org"
                                                    }];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.notificationDelegate failedObservationFetch:error];
        });
    }
}

- (void)removeAllSearchPredicates {
    [self removeAllSearchPredicatesUpdatingObservations:YES];
}

- (void)removeAllSearchPredicatesUpdatingObservations:(BOOL)update {
    lastPagedFetched = 1;
    
    self.activeSearchPredicates = @[];
    
    // clear any stashed objects
    self.observations = [NSOrderedSet orderedSet];
    
    if (update) {
        if ([[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
            [self fetchObservationsShouldNotify:YES];
        } else {
            NSError *error = [NSError errorWithDomain:@"org.inaturalist"
                                                 code:-1008
                                             userInfo:@{
                                                        NSLocalizedDescriptionKey: @"Network unavailable, cannot search iNaturalist.org"
                                                        }];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.notificationDelegate failedObservationFetch:error];
            });
        }
    }
}

- (void)expandActiveSearchToNextPageOfResults {
    if ([[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        [self fetchObservationsPage:++lastPagedFetched];
    } else {
        NSError *error = [NSError errorWithDomain:@"org.inaturalist"
                                             code:-1008
                                         userInfo:@{
                                                    NSLocalizedDescriptionKey: @"Network unavailable, cannot search iNaturalist.org"
                                                    }];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.notificationDelegate failedObservationFetch:error];
        });
    }
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
    NSString *pathPattern = @"observations";
    // for iOS, we treat "mappable" as "exploreable"
    NSString *query = @"?per_page=100&mappable=true";
    
    NSString *localeString = [NSLocale inat_serverFormattedLocale];
    if (localeString && ![localeString isEqualToString:@""]) {
        query = [query stringByAppendingString:[NSString stringWithFormat:@"&locale=%@", localeString]];
    }
    
    BOOL hasActiveLocationPredicate = NO;
    
    // apply active search predicates to the query
    if (predicates.count > 0) {
        for (ExploreSearchPredicate *predicate in predicates) {
            if (predicate.type == ExploreSearchPredicateTypePerson) {
                // people search requires a differnt baseurl and thus different path pattern
                query = [query stringByAppendingString:[NSString stringWithFormat:@"&user_id=%ld", (long)predicate.searchPerson.personId]];
            } else if (predicate.type == ExploreSearchPredicateTypeCritter) {
                query = [query stringByAppendingString:[NSString stringWithFormat:@"&taxon_id=%ld", (long)predicate.searchTaxon.recordID.integerValue]];
            } else if (predicate.type == ExploreSearchPredicateTypeLocation) {
                hasActiveLocationPredicate = YES;
                query = [query stringByAppendingString:[NSString stringWithFormat:@"&place_id=%ld", (long)predicate.searchLocation.locationId]];
            } else if (predicate.type == ExploreSearchPredicateTypeProject) {
                query = [query stringByAppendingString:[NSString stringWithFormat:@"&project_id=%ld", (long)predicate.searchProject.projectId]];
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
                statusMessage = NSLocalizedString(@"Searching for recent observations in map area", nil);
            else
                statusMessage = NSLocalizedString(@"Searching for recent observations worldwide", nil);
        } else {
            if (self.limitingRegion)
                statusMessage = NSLocalizedString(@"Fetching recent observations in map area", nil);
            else
                statusMessage = NSLocalizedString(@"Fetching recent observations worldwide", nil);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.notificationDelegate startedObservationFetch];
        });
    }
    
    [[Analytics sharedClient] debugLog:@"Network - Explore fetch observations"];
    
    NSLog(@"path is %@", path);
    
    INatAPI *api = [[INatAPI alloc] init];
    
    [api fetch:path classMapping:ExploreObservation.class handler:^(NSArray *results, NSInteger count, NSError *error) {
    	NSLog(@"results is %@", results);
        NSSet *trimmedObservations;
        NSSet *unorderedObservations;
        if (self.limitingRegion) {
            trimmedObservations = [self.observations.set bk_select:^BOOL(ExploreObservation *obs) {
                // trim out anything that isn't in the limiting region
                return [self.limitingRegion containsCoordinate:obs.coordinate];
            }];
            unorderedObservations = [trimmedObservations setByAddingObjectsFromArray:results];
        } else {
            unorderedObservations = [self.observations.set setByAddingObjectsFromArray:results];
        }
        NSArray *orderedObservations = [[unorderedObservations allObjects] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return ((ExploreObservation *)obj1).observationId < ((ExploreObservation *)obj2).observationId;
        }];
        
        self.observations = [[NSOrderedSet alloc] initWithArray:orderedObservations];
        
        if (shouldNotify) {
            if (results.count > 0)
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.notificationDelegate finishedObservationFetch];
                });
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSError *error = [[NSError alloc] initWithDomain:@"org.inaturalist"
                                                                code:-1014
                                                            userInfo:@{ NSLocalizedDescriptionKey: @"No observations found." }];
                    [self.notificationDelegate failedObservationFetch:error];
                });
            }
        }
    }];
}

- (NSString *)combinedColloquialSearchPhrase {
    NSMutableString *colloquial = [[NSMutableString alloc] init];
    
    for (ExploreSearchPredicate *predicate in self.activeSearchPredicates) {
        if ([self.activeSearchPredicates indexOfObject:predicate] == 0)
            [colloquial appendString:predicate.colloquialSearchPhrase];
        else
            [colloquial appendFormat:NSLocalizedString(@" and %@", nil), predicate.colloquialSearchPhrase]; // unlocalizable way to build sentances
    }
    
    // Capitalize the first character of the combined search phrase.
    // This will not work in languages that are right to left, but then neither
    // will this entire method.
    if (colloquial.length > 0) {
        colloquial = [[colloquial stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                                          withString:[[colloquial substringToIndex:1] uppercaseString]] mutableCopy];
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

- (NSArray *)observationsWithPhotos {
    return [self.observations.array bk_select:^BOOL(ExploreObservation *observation) {
        return observation.observationPhotos.count > 0;
    }];
}

- (BOOL)hasActiveLocationSearchPredicate {
    return [self.activeSearchPredicates bk_any:^BOOL(ExploreSearchPredicate *p) {
        return p.type == ExploreSearchPredicateTypeLocation;
    }];
}

- (void)addIdentificationTaxonId:(NSInteger)taxonId forObservation:(ExploreObservation *)observation completionHandler:(PostCompletionHandler)handler {
    [[Analytics sharedClient] debugLog:@"Network - Explore Add Comment"];
    [self postToPath:@"/identifications"
              params:@{ @"identification[observation_id]": @(observation.observationId),
                        @"identification[taxon_id]": @(taxonId) }
          completion:handler];
}

- (void)addComment:(NSString *)commentBody forObservation:(ExploreObservation *)observation completionHandler:(PostCompletionHandler)handler {
    [[Analytics sharedClient] debugLog:@"Network - Explore Add Comment"];
    [self postToPath:@"/comments"
              params:@{ @"comment[body]": commentBody,
                        @"comment[parent_id]": @(observation.observationId),
                        @"comment[parent_type]": @"Observation" }
          completion:handler];
}

- (void)postToPath:(NSString *)path params:(NSDictionary *)params completion:(PostCompletionHandler)handler {
    
    [[RKClient sharedClient] post:path usingBlock:^(RKRequest *request) {
        request.params = params;
        
        request.onDidLoadResponse = ^(RKResponse *response) {
            handler(response, nil);
        };
        
        request.onDidFailLoadWithError = ^(NSError *err) {
            handler(nil, err);
        };
    }];
}

- (void)loadCommentsAndIdentificationsForObservation:(ExploreObservation *)observation completionHandler:(FetchCompletionHandler)handler {
    NSString *path = [NSString stringWithFormat:@"/observations/%ld.json", (long)observation.observationId];
    NSString *localeString = [NSLocale inat_serverFormattedLocale];
    if (localeString && ![localeString isEqualToString:@""]) {
        path = [path stringByAppendingString:[NSString stringWithFormat:@"?locale=%@", localeString]];
    }
    
    [[Analytics sharedClient] debugLog:@"Network - Explore fetch comments and IDs for observation"];
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:path usingBlock:^(RKObjectLoader *loader) {
        loader.method = RKRequestMethodGET;
        loader.objectMapping = [ExploreMappingProvider observationMapping];
        
        loader.onDidLoadObjects = ^(NSArray *results) {
            handler(results, nil);
        };
        
        loader.onDidFailWithError = ^(NSError *err) {
            handler(nil, err);
        };
        
        loader.onDidFailLoadWithError = ^(NSError *err) {
            handler(nil, err);
        };
    }];
}

- (NSString *)pathForLeaderboardSearchPredicates:(NSArray *)predicates {
    
    NSString *path = @"observations/observers";
    
    NSString *query = @"";
    
    // apply active search predicates to the query
    if (predicates.count > 0) {
        for (ExploreSearchPredicate *predicate in predicates) {
            NSString *join = @"&";
            if ([predicates indexOfObject:predicate] == 0) {
                join = @"?";
            }
            if (predicate.type == ExploreSearchPredicateTypePerson) {
                query = [query stringByAppendingString:[NSString stringWithFormat:@"%@user_id=%ld",
                                                        join, (long)predicate.searchPerson.personId]];
            } else if (predicate.type == ExploreSearchPredicateTypeCritter) {
                query = [query stringByAppendingString:[NSString stringWithFormat:@"%@taxon_id=%ld",
                                                        join, (long)predicate.searchTaxon.recordID.integerValue]];
            } else if (predicate.type == ExploreSearchPredicateTypeLocation) {
                query = [query stringByAppendingString:[NSString stringWithFormat:@"%@place_id=%ld",
                                                        join, (long)predicate.searchLocation.locationId]];
            } else if (predicate.type == ExploreSearchPredicateTypeProject) {
                query = [query stringByAppendingString:[NSString stringWithFormat:@"%@project_id=%ld",
                                                        join, (long)predicate.searchProject.projectId]];
            }
        }
    }
    
    return [NSString stringWithFormat:@"%@%@", path, query];
}


- (void)loadLeaderboardCompletion:(FetchCompletionHandler)handler {
    NSString *path = [self pathForLeaderboardSearchPredicates:self.activeSearchPredicates];
    
    INatAPI *api = [[INatAPI alloc] init];
    [api fetch:path mapping:[ExploreMappingProvider observerCountMapping] handler:^(NSArray *results, NSError *error) {
        if (error) {
            handler(nil, error);
            return;
        } else {
            handler(results, nil);
        }
    }];
}

#pragma mark - Notification

- (BOOL)isFetching {
    if ([[[RKClient sharedClient] requestQueue] count] == 0)
        return NO;
    
    if ([[[RKClient sharedClient] requestQueue] loadingCount] == 0)
        return NO;
    
    return YES;
}

@end
