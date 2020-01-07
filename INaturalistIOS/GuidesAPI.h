//
//  GuidesAPI.h
//  iNaturalist
//
//  Created by Alex Shepard on 11/15/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#import "INatRailsAPI.h"

@interface GuidesAPI : INatRailsAPI

- (void)guidesForLoggedInUserHandler:(INatAPIFetchCompletionCountHandler)done;
- (void)guidesNearLocation:(CLLocationCoordinate2D)coordinate handler:(INatAPIFetchCompletionCountHandler)done;
- (void)guidesMatching:(NSString *)searchTerm handler:(INatAPIFetchCompletionCountHandler)done;

@end
