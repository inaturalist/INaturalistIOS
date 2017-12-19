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
#import "ExploreObservation.h"
#import "ExploreLocation.h"
#import "ExploreProject.h"
#import "ExploreUser.h"
#import "ExploreTaxon.h"
#import "NSURL+INaturalist.h"
#import "NSLocale+INaturalist.h"
#import "Analytics.h"
#import "INatAPI.h"
#import "ObserverCount.h"
#import "INatReachability.h"

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
    if ([[INatReachability sharedClient] isNetworkReachable]) {
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

    if ([[INatReachability sharedClient] isNetworkReachable]) {
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
	
    if ([[INatReachability sharedClient] isNetworkReachable]) {
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
	
    if ([[INatReachability sharedClient] isNetworkReachable]) {
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
        if ([[INatReachability sharedClient] isNetworkReachable]) {
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
    if ([[INatReachability sharedClient] isNetworkReachable]) {
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
	NSString *query = @"?per_page=100&mappable=true&verifiable=true";
	
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
				query = [query stringByAppendingString:[NSString stringWithFormat:@"&user_id=%ld", (long)predicate.searchPerson.userId]];
			} else if (predicate.type == ExploreSearchPredicateTypeCritter) {
				query = [query stringByAppendingString:[NSString stringWithFormat:@"&taxon_id=%ld", (long)predicate.searchTaxon.taxonId]];
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
	[self.api fetch:path classMapping:ExploreObservation.class handler:^(NSArray *results, NSInteger count, NSError *error) {
        if (error) {
            [self.notificationDelegate failedObservationFetch:error];
            return;
        }
        
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
														join, (long)predicate.searchPerson.userId]];
			} else if (predicate.type == ExploreSearchPredicateTypeCritter) {
				query = [query stringByAppendingString:[NSString stringWithFormat:@"%@taxon_id=%ld",
														join, (long)predicate.searchTaxon.taxonId]];
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
	
	[self.api fetch:path classMapping:ObserverCount.class handler:^(NSArray *results, NSInteger count, NSError *error) {
		if (error) {
			handler(nil, error);
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
