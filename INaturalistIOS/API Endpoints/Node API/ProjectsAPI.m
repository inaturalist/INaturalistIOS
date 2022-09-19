//
//  ProjectsAPI.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/1/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ProjectsAPI.h"
#import "Project.h"
#import "ExploreObservation.h"
#import "ObserverCount.h"
#import "IdentifierCount.h"
#import "SpeciesCount.h"
#import "Analytics.h"
#import "NSLocale+INaturalist.h"
#import "ExploreProject.h"

@implementation ProjectsAPI

- (NSInteger)projectsPerPage {
    return 100;
}

- (NSInteger)observationsProjectPerPage {
    return 200;
}

- (void)projectsForUser:(NSInteger)userId page:(NSInteger)page handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch a page of user projects from node"];
    NSString *path =[NSString stringWithFormat:@"users/%ld/projects?per_page=%ld&page=%ld",
                     (long)userId, (long)self.projectsPerPage, (long)page];
    [self fetch:path classMapping:ExploreProject.class handler:done];
}

-(void)featuredProjectsHandler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch featured projects from node"];
    NSString *path =[NSString stringWithFormat:@"projects?featured=true&per_page=%ld",
                     (long)self.projectsPerPage];
    [self fetch:path classMapping:ExploreProject.class handler:done];
}

- (void)projectsNearLocation:(CLLocationCoordinate2D)coordinate handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch nearby projects from node"];
    NSString *path =[NSString stringWithFormat:@"projects?per_page=%ld&lat=%f&lng=%f&order_by=distance&spam=false",
                     (long)self.projectsPerPage, coordinate.latitude, coordinate.longitude];
    [self fetch:path classMapping:ExploreProject.class handler:done];
}

- (void)projectsMatching:(NSString *)searchTerm handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - search for projects from node"];
    NSString *path =[NSString stringWithFormat:@"projects?per_page=%ld&q=%@&spam=false",
                     (long)self.projectsPerPage, searchTerm];
    [self fetch:path classMapping:ExploreProject.class handler:done];
}

- (void)joinProject:(NSInteger)projectId handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - join project via node"];
    NSString *path =[NSString stringWithFormat:@"projects/%ld/join",
                     (long)projectId];
    [self post:path params:nil classMapping:ExploreProject.class handler:done];
}

- (void)leaveProject:(NSInteger)projectId handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - join project via node"];
    NSString *path =[NSString stringWithFormat:@"projects/%ld/leave",
                     (long)projectId];
    [self delete:path handler:done];
}



- (void)observationsForProjectId:(NSInteger)projectId handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch observations for project from node"];
    NSString *path = [NSString stringWithFormat:@"observations?project_id=%ld&per_page=%ld",
                      (long)projectId, (long)self.observationsProjectPerPage];
    [self fetch:path classMapping:[ExploreObservation class] handler:done];
}

- (void)speciesCountsForProjectId:(NSInteger)projectId handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch species counts for project from node"];
    NSString *path = [NSString stringWithFormat:@"observations/species_counts?project_id=%ld",
                      (long)projectId];
    [self fetch:path classMapping:[SpeciesCount class] handler:done];
}

- (void)observerCountsForProjectId:(NSInteger)projectId handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch observer counts for project from node"];
    NSString *path = [NSString stringWithFormat:@"observations/observers?project_id=%ld",
                      (long)projectId];
    [self fetch:path classMapping:[ObserverCount class] handler:done];
}

- (void)identifierCountsForProjectId:(NSInteger)projectId handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch identifier counts for project from node"];
    NSString *path = [NSString stringWithFormat:@"observations/identifiers?project_id=%ld",
                      (long)projectId];
    [self fetch:path classMapping:[IdentifierCount class] handler:done];
}


@end
