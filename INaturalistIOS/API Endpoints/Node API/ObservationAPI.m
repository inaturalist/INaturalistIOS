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
    NSString *path = [NSString stringWithFormat:@"observations?user_id=%ld&per_page=%ld&details=all",
                      (long)userId, (long)count];;
    [self fetch:path classMapping:ExploreObservation.class handler:done];
}

- (void)observationWithId:(NSInteger)identifier handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch observation from node"];
    NSString *path = [NSString stringWithFormat:@"observations/%ld?ttl=-1", (long)identifier];
    [self fetch:path classMapping:ExploreObservation.class handler:done];
}

- (void)updatesWithHandler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch observation updates from node"];
    NSString *path = @"observations/updates?per_page=200&observations_by=owner";
    [self fetch:path classMapping:ExploreUpdate.class handler:done];
}

- (void)seenUpdatesForObservationId:(NSInteger)identifier handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - mark seen updates via node"];
    NSString *path = [NSString stringWithFormat:@"observations/%ld/viewed_updates", (long)identifier];
    [self put:path params:nil classMapping:nil handler:done];
}

- (void)topObserversForTaxaIds:(NSArray *)taxaIds handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch top observers from node"];
    NSString *path = [NSString stringWithFormat:@"observations/observers?per_page=3&taxon_id=%@",
                      [taxaIds componentsJoinedByString:@","]];
    [self fetch:path classMapping:ObserverCount.class handler:done];
}

- (void)topIdentifiersForTaxaIds:(NSArray *)taxaIds handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch top identifiers from node"];
    NSString *path = [NSString stringWithFormat:@"observations/identifiers?per_page=3&taxon_id=%@",
                      [taxaIds componentsJoinedByString:@","]];
    [self fetch:path classMapping:IdentifierCount.class handler:done];
}

- (void)faveObservationWithId:(NSInteger)identifier handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fave observation via node"];
    NSString *path = [NSString stringWithFormat:@"observations/%ld/fave", (long)identifier];
    [self post:path params:nil classMapping:[ExploreObservation class] handler:done];
}

- (void)unfaveObservationWithId:(NSInteger)identifier handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fave observation via node"];
    NSString *path = [NSString stringWithFormat:@"observations/%ld/unfave", (long)identifier];
    [self delete:path handler:done];
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
    
    NSString *path = [NSString stringWithFormat:@"observations/deleted?since=%@", sinceDateString];
    [self fetch:path classMapping:NSNumber.class handler:done];
}

@end
