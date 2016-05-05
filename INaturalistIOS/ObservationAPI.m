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


- (void)observationWithId:(NSInteger)identifier handler:(INatAPIFetchCompletionHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch observation from node"];
    NSString *path = [NSString stringWithFormat:@"observations/%ld", (long)identifier];
    [self fetch:path mapping:[ExploreMappingProvider observationMapping] handler:done];
}

@end
