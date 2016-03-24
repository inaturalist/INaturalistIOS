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

@implementation ObservationAPI


- (void)observationWithId:(NSInteger)identifier handler:(INatAPIFetchCompletionHandler)done {
    NSString *path = [NSString stringWithFormat:@"observations/%ld", identifier];
    [self fetch:path mapping:[ExploreMappingProvider observationMapping] handler:done];
}

@end
