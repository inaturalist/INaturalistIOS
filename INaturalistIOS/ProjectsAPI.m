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

@implementation ProjectsAPI

- (void)observationsForProject:(Project *)project handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch observations for project from node"];
    NSString *path = [NSString stringWithFormat:@"observations?project_id=%ld&per_page=200",
                      (long)project.recordID.integerValue];
    [self fetch:path classMapping:[ExploreObservation class] handler:done];
}

- (void)speciesCountsForProject:(Project *)project handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch species counts for project from node"];
    NSString *path = [NSString stringWithFormat:@"observations/species_counts?project_id=%ld",
                      (long)project.recordID.integerValue];
    [self fetch:path classMapping:[SpeciesCount class] handler:done];
}

- (void)observerCountsForProject:(Project *)project handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch observer counts for project from node"];
    NSString *path = [NSString stringWithFormat:@"observations/observers?project_id=%ld",
                      (long)project.recordID.integerValue];
    [self fetch:path classMapping:[ObserverCount class] handler:done];
}

- (void)identifierCountsForProject:(Project *)project handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch identifier counts for project from node"];
    NSString *path = [NSString stringWithFormat:@"observations/identifiers?project_id=%ld",
                      (long)project.recordID.integerValue];
    [self fetch:path classMapping:[IdentifierCount class] handler:done];
}

- (void)fetch:(NSString *)path classMapping:(Class)classForMapping handler:(INatAPIFetchCompletionCountHandler)done {
    NSString *localeString = [NSLocale inat_serverFormattedLocale];
    if (localeString && ![localeString isEqualToString:@""]) {
        path = [path stringByAppendingString:[NSString stringWithFormat:@"&locale=%@", localeString]];
    }
    
    [super fetch:path classMapping:classForMapping handler:done];
}


@end
