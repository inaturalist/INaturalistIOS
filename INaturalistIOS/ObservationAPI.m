//
//  ObservationAPI.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/1/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ObservationAPI.h"
#import "ExploreObservation.h"
#import "ExploreMappingProvider.h"
#import "Analytics.h"

@implementation ObservationAPI

- (void)observationWithId:(NSInteger)identifier handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch observation from node"];
    NSString *path = [NSString stringWithFormat:@"observations/%ld", (long)identifier];
    [self fetch:path classMapping:ExploreObservation.class handler:done];
}

@end
