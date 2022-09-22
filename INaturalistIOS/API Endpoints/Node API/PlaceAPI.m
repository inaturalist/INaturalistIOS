//
//  PlaceAPI.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/11/21.
//  Copyright © 2021 iNaturalist. All rights reserved.
//

#import "PlaceAPI.h"
#import "Analytics.h"
#import "ExploreLocation.h"

@implementation PlaceAPI

- (void)placesMatching:(NSString *)searchTerm handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - search for places from node"];
    NSString *path = @"/v1/places/autocomplete";
    NSString *query = [NSString stringWithFormat:@"autocomplete?q=%@", searchTerm];
    [self fetch:path query:query classMapping:ExploreLocation.class handler:done];
}

@end
