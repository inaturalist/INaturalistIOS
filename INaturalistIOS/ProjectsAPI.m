//
//  ProjectsAPI.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/1/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ProjectsAPI.h"
#import "Project.h"
#import "ExploreMappingProvider.h"
#import "ExploreObservation.h"
#import "ObserverCount.h"
#import "IdentifierCount.h"
#import "SpeciesCount.h"

@implementation ProjectsAPI

- (void)observationsForProject:(Project *)project handler:(INatAPIFetchCompletionCountHandler)done {
    NSString *path = [NSString stringWithFormat:@"observations?project_id=%ld&per_page=200",
                      (long)project.recordID.integerValue];
    [self fetchWithCount:path mapping:[ExploreMappingProvider observationMapping] handler:done];
}

- (void)speciesCountsForProject:(Project *)project handler:(INatAPIFetchCompletionCountHandler)done {
    NSString *path = [NSString stringWithFormat:@"observations/species_counts?project_id=%ld",
                      (long)project.recordID.integerValue];
    [self fetchWithCount:path mapping:[ExploreMappingProvider speciesCountMapping] handler:done];
}

- (void)observerCountsForProject:(Project *)project handler:(INatAPIFetchCompletionCountHandler)done {
    NSString *path = [NSString stringWithFormat:@"observations/observers?project_id=%ld",
                      (long)project.recordID.integerValue];
    [self fetchWithCount:path mapping:[ExploreMappingProvider observerCountMapping] handler:done];
}

- (void)identifierCountsForProject:(Project *)project handler:(INatAPIFetchCompletionCountHandler)done {
    NSString *path = [NSString stringWithFormat:@"observations/identifiers?project_id=%ld",
                      (long)project.recordID.integerValue];
    [self fetchWithCount:path mapping:[ExploreMappingProvider identifierCountMapping] handler:done];
}

@end
