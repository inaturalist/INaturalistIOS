//
//  ProjectsAPI.h
//  iNaturalist
//
//  Created by Alex Shepard on 3/1/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "INatAPI.h"

@interface ProjectsAPI : INatAPI

- (void)observationsForProject:(Project *)project handler:(INatAPIFetchCompletionCountHandler)done;
- (void)speciesCountsForProject:(Project *)project handler:(INatAPIFetchCompletionCountHandler)done;
- (void)observerCountsForProject:(Project *)project handler:(INatAPIFetchCompletionCountHandler)done;
- (void)identifierCountsForProject:(Project *)project handler:(INatAPIFetchCompletionCountHandler)done;

@end
