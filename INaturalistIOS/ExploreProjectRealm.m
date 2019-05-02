//
//  ExploreProjectRealm.m
//  iNaturalistTests
//
//  Created by Alex Shepard on 10/10/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import "ExploreProjectRealm.h"

@implementation ExploreProjectRealmSiteFeatures
- (instancetype)initWithMantleModel:(ExploreProjectSiteFeatures *)model {
    if (self = [super init]) {
        self.siteId = model.siteId;
        self.featuredAt = model.featuredAt;
    }
    return self;
}


@end

@implementation ExploreProjectRealm

- (instancetype)initWithMantleModel:(ExploreProject *)model {
    if (self = [super init]) {
        self.title = model.title;
        self.projectId = model.projectId;
        self.locationId = model.locationId;
        self.latitude = model.latitude;
        self.longitude = model.longitude;
        self.iconUrlString = model.iconUrl.absoluteString;
        self.terms = model.terms;
        self.inatDescription = model.inatDescription;
        for (ExploreProjectSiteFeatures *siteFeatures in model.siteFeatures) {
            ExploreProjectRealmSiteFeatures *eprsf = [[ExploreProjectRealmSiteFeatures alloc] initWithMantleModel:siteFeatures];
            [self.siteFeatures addObject:eprsf];
        }
        
        for (ExploreProjectObservationField *field in model.fields) {
            ExploreProjectObservationFieldRealm *epofr = [[ExploreProjectObservationFieldRealm alloc] initWithMantleModel:field];
            [self.fields addObject:epofr];
        }
    }
    
    return self;
}

- (NSURL *)iconUrl {
    return [NSURL URLWithString:self.iconUrlString];
}

- (CLLocation *)location {
    if (self.latitude == 0.0 || self.longitude == 0.0) {
        return nil;
    } else {
        return [[CLLocation alloc] initWithLatitude:self.latitude longitude:self.longitude];
    }
}

- (RLMResults<ExploreProjectObservationFieldRealm *> *)requiredFields {
    return [self.fields objectsWhere:@"required == TRUE"];
}

+ (NSString *)primaryKey {
    return @"projectId";
}

+ (RLMResults *)featuredProjectsForSite:(NSInteger *)siteId {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SUBQUERY(siteFeatures, $siteFeature, $siteFeature.featuredAt != NIL AND $siteFeature.siteId == %d) .@count > 0", siteId];
    RLMResults *results = [[self class] objectsWithPredicate:predicate];
    RLMSortDescriptor *sort = [RLMSortDescriptor sortDescriptorWithKeyPath:@"title" ascending:YES];
    return [results sortedResultsUsingDescriptors:@[ sort ]];
}

+ (RLMResults *)projectsWithLocations {
    return [[self class] objectsWhere:@"latitude != 0.0 AND longitude != 0.0"];
}

+ (RLMResults *)projectsNear:(CLLocation *)location {
    // start with projects with a location
    RLMResults *projectsWithLocations = [self projectsWithLocations];
    
    // TOOD: this is super inefficient
    // anything less than 310 miles away is "nearby"
    NSMutableArray *projectsNearby = [NSMutableArray array];
    for (ExploreProjectRealm *epr in projectsWithLocations) {
        if ([epr.location distanceFromLocation:location] < 500000) {
            [projectsNearby addObject:epr];
        }
    }
    
    // sort nearby projects by how near they are to the passed in location
    NSComparator nearnessComparator = ^NSComparisonResult(ExploreProjectRealm *epr1, ExploreProjectRealm *epr2) {
        return [epr1.location distanceFromLocation:location] > [epr2.location distanceFromLocation:location];
    };
    return [projectsNearby sortedArrayUsingComparator:nearnessComparator];
}

+ (RLMResults *)joinedProjects {
    return [[self class] objectsWhere:@"joined == TRUE"];
}

@end
