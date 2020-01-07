//
//  ProjectsAPI.h
//  iNaturalist
//
//  Created by Alex Shepard on 3/1/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#import "INatAPI.h"

@interface ProjectsAPI : INatAPI

- (void)projectsForUser:(NSInteger)userId handler:(INatAPIFetchCompletionCountHandler)done;
- (void)featuredProjectsHandler:(INatAPIFetchCompletionCountHandler)done;
- (void)projectsNearLocation:(CLLocationCoordinate2D)coordinate handler:(INatAPIFetchCompletionCountHandler)done;
- (void)projectsMatching:(NSString *)searchTerm handler:(INatAPIFetchCompletionCountHandler)done;
- (void)joinProject:(NSInteger)projectId handler:(INatAPIFetchCompletionCountHandler)done;
- (void)leaveProject:(NSInteger)projectId handler:(INatAPIFetchCompletionCountHandler)done;

- (void)observationsForProjectId:(NSInteger)projectId handler:(INatAPIFetchCompletionCountHandler)done;
- (void)speciesCountsForProjectId:(NSInteger)projectId handler:(INatAPIFetchCompletionCountHandler)done;
- (void)observerCountsForProjectId:(NSInteger)projectId handler:(INatAPIFetchCompletionCountHandler)done;
- (void)identifierCountsForProjectId:(NSInteger)projectId handler:(INatAPIFetchCompletionCountHandler)done;

@end
