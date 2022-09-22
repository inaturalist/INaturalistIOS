//
//  ObservationAPI.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/1/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ObservationAPI.h"
#import "ExploreObservation.h"
#import "ExploreUpdate.h"
#import "IdentifierCount.h"
#import "ObserverCount.h"
#import "IdentifierCount.h"
#import "Analytics.h"
#import "Observation.h"

@implementation ObservationAPI

- (void)observationsForUserId:(NSInteger)userId count:(NSInteger)count handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch user observation from node"];
    NSString *path = @"/v1/observations";
    NSString *query = [NSString stringWithFormat:@"user_id=%ld&per_page=%ld&details=all",
                      (long)userId, (long)count];;
    [self fetch:path query:query classMapping:ExploreObservation.class handler:done];
}

- (void)observationWithId:(NSInteger)identifier handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch observation from node"];
    NSString *path = [NSString stringWithFormat:@"/v1/observations/%ld", (long)identifier];
    NSString *query = @"ttl=-1";
    [self fetch:path query:query classMapping:ExploreObservation.class handler:done];
}

- (void)updatesWithHandler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch observation updates from node"];
    NSString *path = @"/v1/observations/updates";
    NSString *query = @"per_page=200&observations_by=owner";
    [self fetch:path query:query classMapping:ExploreUpdate.class handler:done];
}

- (void)seenUpdatesForObservationId:(NSInteger)identifier handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - mark seen updates via node"];
    NSString *path = [NSString stringWithFormat:@"/v1/observations/%ld/viewed_updates", (long)identifier];
    [self put:path query:nil params:nil classMapping:nil handler:done];
}

- (void)topObserversForTaxaIds:(NSArray *)taxaIds handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch top observers from node"];
    NSString *path = @"/v1/observations/observers";
    NSString *query = [NSString stringWithFormat:@"per_page=3&taxon_id=%@",
                       [taxaIds componentsJoinedByString:@","]];
    [self fetch:path query:query classMapping:ObserverCount.class handler:done];
}

- (void)topIdentifiersForTaxaIds:(NSArray *)taxaIds handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch top identifiers from node"];
    NSString *path = @"/v1/observations/identifiers";
    NSString *query = [NSString stringWithFormat:@"per_page=3&taxon_id=%@",
                       [taxaIds componentsJoinedByString:@","]];
    [self fetch:path query:query classMapping:IdentifierCount.class handler:done];
}

- (void)faveObservationWithId:(NSInteger)identifier handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fave observation via node"];
    NSString *path = [NSString stringWithFormat:@"/v1/observations/%ld/fave", (long)identifier];
    [self post:path query:nil params:nil classMapping:[ExploreObservation class] handler:done];
}

- (void)unfaveObservationWithId:(NSInteger)identifier handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fave observation via node"];
    NSString *path = [NSString stringWithFormat:@"/v1/observations/%ld/unfave", (long)identifier];
    [self delete:path query:nil handler:done];
}

- (void)fetchDeletedObservationsSinceDate:(NSDate *)sinceDate handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch deleted observations via node"];
    
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        dateFormatter.dateFormat = @"yyyy-MM-dd";
    }
    NSString *sinceDateString = [dateFormatter stringFromDate:sinceDate];
    
    NSString *path = @"/v1/observations/deleted";
    NSString *query = [NSString stringWithFormat:@"since=%@", sinceDateString];
    [self fetch:path query:query classMapping:NSNumber.class handler:done];
}

@end
