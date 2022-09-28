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
    NSString *path = [NSString stringWithFormat:@"/v1/users/%ld/projects", (long)userId];
    NSString *query = [NSString stringWithFormat:@"per_page=%ld&page=%ld",
                      (long)self.projectsPerPage, (long)page];
    [self fetch:path query:query classMapping:ExploreProject.class handler:done];
}

-(void)featuredProjectsHandler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch featured projects from node"];
    NSString *path = @"/v1/projects";
    NSString *query = [NSString stringWithFormat:@"featured=true&per_page=%ld",
                     (long)self.projectsPerPage];
    [self fetch:path query:query classMapping:ExploreProject.class handler:done];
}

- (void)projectsNearLocation:(CLLocationCoordinate2D)coordinate handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch nearby projects from node"];
    NSString *path = @"/v1/projects";
    NSString *query = [NSString stringWithFormat:@"per_page=%ld&lat=%f&lng=%f&order_by=distance&spam=false",
                     (long)self.projectsPerPage, coordinate.latitude, coordinate.longitude];
    [self fetch:path query:query classMapping:ExploreProject.class handler:done];
}

- (void)projectsMatching:(NSString *)searchTerm handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - search for projects from node"];
    NSString *path = @"/v1/projects";
    NSString *query = [NSString stringWithFormat:@"per_page=%ld&q=%@&spam=false",
                     (long)self.projectsPerPage, searchTerm];
    [self fetch:path query:query classMapping:ExploreProject.class handler:done];
}

- (void)joinProject:(NSInteger)projectId handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - join project via node"];
    NSString *path =[NSString stringWithFormat:@"/v1/projects/%ld/join",
                     (long)projectId];
    [self post:path query:nil params:nil classMapping:ExploreProject.class handler:done];
}

- (void)leaveProject:(NSInteger)projectId handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - join project via node"];
    NSString *path = [NSString stringWithFormat:@"/v1/projects/%ld/leave",
                     (long)projectId];
    [self delete:path query:nil handler:done];
}



- (void)observationsForProjectId:(NSInteger)projectId handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch observations for project from node"];
    NSString *path = @"/v1/observations";
    NSString *query = [NSString stringWithFormat:@"project_id=%ld&per_page=%ld",
                      (long)projectId, (long)self.observationsProjectPerPage];
    [self fetch:path query:query classMapping:[ExploreObservation class] handler:done];
}

- (void)speciesCountsForProjectId:(NSInteger)projectId handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch species counts for project from node"];
    NSString *path = @"/v1/observations/species_counts";
    NSString *query = [NSString stringWithFormat:@"project_id=%ld", (long)projectId];
    [self fetch:path query:query classMapping:[SpeciesCount class] handler:done];
}

- (void)observerCountsForProjectId:(NSInteger)projectId handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch observer counts for project from node"];
    NSString *path = @"/v1/observations/observers";
    NSString *query = [NSString stringWithFormat:@"project_id=%ld", (long)projectId];
    [self fetch:path query:query classMapping:[ObserverCount class] handler:done];
}

- (void)identifierCountsForProjectId:(NSInteger)projectId handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch identifier counts for project from node"];
    NSString *path = @"/v1/observations/identifiers";
    NSString *query = [NSString stringWithFormat:@"project_id=%ld", (long)projectId];
    [self fetch:path query:query classMapping:[IdentifierCount class] handler:done];
}


@end
