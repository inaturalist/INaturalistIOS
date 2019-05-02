//
//  ProjectsAPI.h
//  iNaturalist
//
//  Created by Alex Shepard on 3/1/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#import "INatAPI.h"
#import "ProjectVisualization.h"

@interface ProjectsAPI : INatAPI

- (void)observationsForProject:(id <ProjectVisualization>)project handler:(INatAPIFetchCompletionCountHandler)done;
- (void)speciesCountsForProject:(id <ProjectVisualization>)project handler:(INatAPIFetchCompletionCountHandler)done;
- (void)observerCountsForProject:(id <ProjectVisualization>)project handler:(INatAPIFetchCompletionCountHandler)done;
- (void)identifierCountsForProject:(id <ProjectVisualization>)project handler:(INatAPIFetchCompletionCountHandler)done;

- (void)featuredProjectsHandler:(INatAPIFetchCompletionCountHandler)done;
- (void)searchProjectsTitleText:(NSString *)text handler:(INatAPIFetchCompletionCountHandler)done;
- (void)joinedProjectsUserId:(NSInteger)userId handler:(INatAPIFetchCompletionCountHandler)done;
- (void)projectsNear:(CLLocationCoordinate2D)coordinate radius:(NSInteger)radius handler:(INatAPIFetchCompletionCountHandler)done;

- (void)joinProject:(NSInteger)projectId handler:(INatAPIFetchCompletionCountHandler)done;
- (void)leaveProject:(NSInteger)projectId handler:(INatAPIFetchCompletionCountHandler)done;

@end
