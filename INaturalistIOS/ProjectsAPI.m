//
//  ProjectsAPI.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/1/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ProjectsAPI.h"
#import "ExploreObservation.h"
#import "ExploreProject.h"
#import "ObserverCount.h"
#import "IdentifierCount.h"
#import "SpeciesCount.h"
#import "Analytics.h"
#import "NSLocale+INaturalist.h"

@implementation ProjectsAPI

- (void)observationsForProject:(id <ProjectVisualization>)project handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch observations for project from node"];
    NSString *path = [NSString stringWithFormat:@"observations?project_id=%ld&per_page=200",
                      (long)project.projectId];
    [self fetch:path classMapping:[ExploreObservation class] handler:done];
}

- (void)speciesCountsForProject:(id <ProjectVisualization>)project handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch species counts for project from node"];
    NSString *path = [NSString stringWithFormat:@"observations/species_counts?project_id=%ld",
                      (long)project.projectId];
    [self fetch:path classMapping:[SpeciesCount class] handler:done];
}

- (void)observerCountsForProject:(id <ProjectVisualization>)project handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch observer counts for project from node"];
    NSString *path = [NSString stringWithFormat:@"observations/observers?project_id=%ld",
                      (long)project.projectId];
    [self fetch:path classMapping:[ObserverCount class] handler:done];
}

- (void)identifierCountsForProject:(id <ProjectVisualization>)project handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch identifier counts for project from node"];
    NSString *path = [NSString stringWithFormat:@"observations/identifiers?project_id=%ld",
                      (long)project.projectId];
    [self fetch:path classMapping:[IdentifierCount class] handler:done];
}

- (void)fetch:(NSString *)path classMapping:(Class)classForMapping handler:(INatAPIFetchCompletionCountHandler)done {
    NSString *localeString = [NSLocale inat_serverFormattedLocale];
    if (localeString && ![localeString isEqualToString:@""]) {
        // TODO: not safe to add this to the URL like this
        // we don't know if we already have params
        path = [path stringByAppendingString:[NSString stringWithFormat:@"&locale=%@", localeString]];
    }
    
    [super fetch:path classMapping:classForMapping handler:done];
}

- (void)featuredProjectsHandler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch featured projects from node"];
    NSString *path = @"projects?featured=true";
    [self fetch:path classMapping:[ExploreProject class] handler:done];
}

- (void)projectsNear:(CLLocationCoordinate2D)coordinate radius:(NSInteger)radius handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch nearby projects from node"];
    NSString *path = [NSString stringWithFormat:@"projects?lat=%f&lng=%f&radius=%ld",
                      coordinate.latitude,
                      coordinate.longitude,
                      radius
                      ];
    [self fetch:path classMapping:[ExploreProject class] handler:done];
}

- (void)searchProjectsTitleText:(NSString *)text handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - search projects from node"];
    NSString *path = [NSString stringWithFormat:@"projects/autocomplete?q=%@", text];
    [self fetch:path classMapping:[ExploreProject class] handler:done];
}

- (void)joinedProjectsUserId:(NSInteger)userId handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch joined projects from node"];
    NSString *path = [NSString stringWithFormat:@"users/%ld/projects", (long)userId];
    [super fetch:path classMapping:[ExploreProject class] handler:done];
}

- (void)joinProject:(NSInteger)projectId handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - join project via node"];
    NSString *path = [NSString stringWithFormat:@"projects/%ld/join", (long)projectId];
    [super post:path params:nil classMapping:nil handler:done];
}

- (void)leaveProject:(NSInteger)projectId handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - leave project via node"];
    NSString *path = [NSString stringWithFormat:@"projects/%ld/leave", (long)projectId];
    [super delete:path handler:done];
}


@end
