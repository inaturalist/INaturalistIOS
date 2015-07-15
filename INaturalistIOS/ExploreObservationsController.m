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

@interface ExploreObservationsController () {
    NSInteger lastPagedFetched;
    ExploreRegion *_limitingRegion;
}
@end

@implementation ExploreObservationsController

@synthesize observations, activeSearchPredicates, notificationDelegate;

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
        [self.notificationDelegate failedObservationFetch:error];
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
        [self.notificationDelegate failedObservationFetch:error];
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
        [self.notificationDelegate failedObservationFetch:error];
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
        [self.notificationDelegate failedObservationFetch:error];
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
            [self.notificationDelegate failedObservationFetch:error];
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
        [self.notificationDelegate failedObservationFetch:error];
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
    NSString *pathPattern = @"/observations.json";
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
                statusMessage = NSLocalizedString(@"Searching for recent observations in map area", nil);
            else
                statusMessage = NSLocalizedString(@"Searching for recent observations worldwide", nil);
        } else {
            if (self.limitingRegion)
                statusMessage = NSLocalizedString(@"Fetching recent observations in map area", nil);
            else
                statusMessage = NSLocalizedString(@"Fetching recent observations worldwide", nil);
        }
        
        [self.notificationDelegate startedObservationFetch];
    }
    
    [[Analytics sharedClient] debugLog:@"Network - Explore fetch observations"];
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
                    [self.notificationDelegate finishedObservationFetch];
                else {
                    NSError *error = [[NSError alloc] initWithDomain:@"org.inaturalist"
                                                                code:-1014
                                                            userInfo:@{ NSLocalizedDescriptionKey: @"No observations found." }];
                    [self.notificationDelegate failedObservationFetch:error];
                }
            }
        };
        
        loader.onDidFailWithError = ^(NSError *err) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            [self.notificationDelegate failedObservationFetch:err];
        };
        
        loader.onDidFailLoadWithError = ^(NSError *err) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            [self.notificationDelegate failedObservationFetch:err];
        };
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
    [self postToPath:@"/identifications"
              params:@{ @"identification[observation_id]": @(observation.observationId),
                        @"identification[taxon_id]": @(taxonId) }
          completion:handler];
}

- (void)addComment:(NSString *)commentBody forObservation:(ExploreObservation *)observation completionHandler:(PostCompletionHandler)handler {
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

- (NSURL *)urlForLeaderboardSpan:(ExploreLeaderboardSpan)span searchPredicates:(NSArray *)predicates {
    
    NSString *d1, *d2;
    
    NSDate *date = [NSDate date];
    NSDateFormatter *monthFormatter = [[NSDateFormatter alloc] init];
    monthFormatter.dateFormat = @"MM";
    NSString *month = [monthFormatter stringFromDate:date];
    
    NSDateFormatter *yearFormatter = [[NSDateFormatter alloc] init];
    yearFormatter.dateFormat = @"yyyy";
    NSString *year = [yearFormatter stringFromDate:date];
    
    NSDateFormatter *ymdFormatter = [[NSDateFormatter alloc] init];
    ymdFormatter.dateFormat = @"yyyy-MM-dd";
    NSString *today = [ymdFormatter stringFromDate:date];
    
    if (span == ExploreLeaderboardSpanYear) {
        d1 = [NSString stringWithFormat:@"%@-01-01", year];
    } else {
        d1 = [NSString stringWithFormat:@"%@-%@-01", year, month];
    }
    d2 = today;

    NSURLComponents *components = [NSURLComponents componentsWithURL:[NSURL inat_baseURL] resolvingAgainstBaseURL:nil];
    components.path = @"/observations/user_stats.json";
    NSString *query = [NSString stringWithFormat:@"d1=%@&d2=%@", d1, d2];
    
    // apply active search predicates to the query
    if (predicates.count > 0) {
        for (ExploreSearchPredicate *predicate in predicates) {
            if (predicate.type == ExploreSearchPredicateTypePerson) {
                query = [query stringByAppendingString:[NSString stringWithFormat:@"&user_id=%ld", (long)predicate.searchPerson.personId]];
            } else if (predicate.type == ExploreSearchPredicateTypeCritter) {
                query = [query stringByAppendingString:[NSString stringWithFormat:@"&taxon_id=%ld", (long)predicate.searchTaxon.recordID.integerValue]];
            } else if (predicate.type == ExploreSearchPredicateTypeLocation) {
                query = [query stringByAppendingString:[NSString stringWithFormat:@"&place_id=%ld", (long)predicate.searchLocation.locationId]];
            } else if (predicate.type == ExploreSearchPredicateTypeProject) {
                query = [query stringByAppendingString:[NSString stringWithFormat:@"&projects[]=%ld", (long)predicate.searchProject.projectId]];
            }
        }
    }
    
    components.query = query;
    return [components URL];
}


- (void)loadLeaderboardSpan:(ExploreLeaderboardSpan)span completion:(FetchCompletionHandler)handler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self urlForLeaderboardSpan:span searchPredicates:self.activeSearchPredicates]];

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (connectionError) {
                                   handler(nil, connectionError);
                                   return;
                               }
                               
                               NSError *jsonError;
                               NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                                                    options:nil
                                                                                      error:&jsonError];
                               if (jsonError) {
                                   handler(nil, jsonError);
                                   return;
                               }
                               
                               NSArray *mostObservations = [json valueForKeyPath:@"most_observations"];
                               NSArray *mostSpecies = [json valueForKeyPath:@"most_species"];
                               
                               NSMutableDictionary *list = [NSMutableDictionary dictionary];
                               [mostObservations bk_each:^(NSDictionary *obsEntry) {
                                   list[[[obsEntry valueForKeyPath:@"user.id"] stringValue]] = [@{
                                                                                                  @"user_id": [obsEntry valueForKeyPath:@"user.id"],
                                                                                                  @"user_login": [obsEntry valueForKeyPath:@"user.login"],
                                                                                                  @"user_icon": [obsEntry valueForKeyPath:@"user.user_icon_url"],
                                                                                                  @"observations_count": [obsEntry valueForKeyPath:@"count"],
                                                                                                  @"species_count": @(0),
                                                                                                  } mutableCopy];
                               }];
                               
                               [mostSpecies bk_each:^(NSDictionary *speciesEntry) {
                                   NSMutableDictionary *user = list[[[speciesEntry valueForKeyPath:@"user.id"] stringValue]];
                                   if (user) {
                                       user[@"species_count"] = [speciesEntry valueForKeyPath:@"count"];
                                   } else {
                                       list[[speciesEntry valueForKeyPath:@"user.id"]] = [@{
                                                                                            @"user_id": [speciesEntry valueForKeyPath:@"user.id"],
                                                                                            @"user_login": [speciesEntry valueForKeyPath:@"user.login"],
                                                                                            @"user_icon": [speciesEntry valueForKeyPath:@"user.user_icon_url"],
                                                                                            @"observations_count": @(0),
                                                                                            @"species_count": [speciesEntry valueForKeyPath:@"count"],
                                                                                            } mutableCopy];
                                   }
                               }];
                               
                               handler(list.allValues, nil);
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
