//
//  YearInReviewAPI.h
//  iNaturalist
//
//  Created by Alex Shepard on 1/8/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import "INatRailsAPI.h"

// this is kind of a weird request, so let's make a weird callback for it
typedef void(^INatAPIYiRStatsHandler)(BOOL generated, NSError *error);

@interface YearInReviewAPI : INatRailsAPI

- (void)generateYiRStatsForYear:(NSInteger)year handler:(INatAPIYiRStatsHandler)done;
- (void)checkIfYiRStatsGeneratedForUser:(NSString *)username year:(NSInteger)year;
- (BOOL)loggedInUserHasGeneratedStatsForYear:(NSInteger)year;


@end
