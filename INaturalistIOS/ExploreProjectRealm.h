//
//  ExploreProjectRealm.h
//  iNaturalistTests
//
//  Created by Alex Shepard on 10/3/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>
#import <CoreLocation/CoreLocation.h>

#import "ExploreProject.h"
#import "ProjectVisualization.h"
#import "ExplorePostRealm.h"
#import "ExploreProjectObservationFieldRealm.h"

@interface ExploreProjectRealmSiteFeatures : RLMObject
@property NSInteger siteId;
@property NSDate *featuredAt;
@end
RLM_ARRAY_TYPE(ExploreProjectRealmSiteFeatures)

@interface ExploreProjectRealm : RLMObject <ProjectVisualization>

@property NSString *title;
@property NSInteger projectId;
@property NSInteger locationId;
@property CLLocationDegrees latitude;
@property CLLocationDegrees longitude;
@property NSString *iconUrlString;
@property BOOL joined;
@property NSString *terms;
@property NSString *inatDescription;

// to-many relationship
@property RLMArray<ExploreProjectRealmSiteFeatures *><ExploreProjectRealmSiteFeatures> *siteFeatures;
@property RLMArray<ExplorePostRealm *><ExplorePostRealm> *posts;
@property RLMArray<ExploreProjectObservationFieldRealm *><ExploreProjectObservationFieldRealm> *fields;

@property (readonly) RLMResults<ExploreProjectObservationFieldRealm *> *requiredFields;

@property (readonly) NSURL *iconUrl;
@property (readonly) NSDate *featuredAt;
@property (readonly) CLLocation *location;

- (instancetype)initWithMantleModel:(ExploreProject *)model;

+ (RLMResults *)featuredProjectsForSite:(NSInteger)siteId;
+ (RLMResults *)projectsNear:(CLLocation *)location;
+ (RLMResults *)projectsWithLocations;
+ (RLMResults *)joinedProjects;



@end
