//
//  ObservationAPI.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/1/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <RestKit/RestKit.h>

#import "ObservationAPI.h"
#import "ExploreObservation.h"
#import "ExploreUpdate.h"
#import "IdentifierCount.h"
#import "ObserverCount.h"
#import "IdentifierCount.h"
#import "Analytics.h"

@implementation ObservationAPI

- (void)observationWithId:(NSInteger)identifier handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch observation from node"];
    NSString *path = [NSString stringWithFormat:@"observations/%ld", (long)identifier];
    [self fetch:path classMapping:ExploreObservation.class handler:done];
}

- (void)updatesWithHandler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch observation updates from node"];
    NSString *path = @"observations/updates?per_page=100";
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

- (void)observationsForUserId:(NSInteger)userId count:(NSInteger)count handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch observations for user"];
    NSString *path = [NSString stringWithFormat:@"observations?user_id=%ld&per_page=%ld",
                      (long)userId, (long)count];
    [self fetch:path classMapping:ExploreObservation.class handler:done];
}

- (void)deletedObservationsSinceDate:(NSDate *)date handler:(INatAPIFetchCompletionCountHandler)done {
    if (!date) { return; }
    
    static NSDateFormatter *dateFormatter = nil;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd";
    }
    NSString *dateString = [dateFormatter stringFromDate:date];
    
    [[Analytics sharedClient] debugLog:@"Network - fetch deleted records for user"];
    NSString *path = [NSString stringWithFormat:@"observations/deleted?since=%@", dateString];
    [self fetch:path classMapping:NSNumber.class handler:done];
}

- (void)dealloc {
    [[[RKClient sharedClient] requestQueue] cancelRequestsWithDelegate:(id <RKRequestDelegate>)self];
}

@end
