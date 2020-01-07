//
//  ExploreProjectRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 1/6/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>

#import "ExploreProject.h"
#import "Project.h"
#import "ProjectVisualization.h"

@interface ExploreProjectRealm : RLMObject <ProjectVisualization>

@property NSString *title;
@property NSInteger projectId;
@property NSInteger locationId;
@property CLLocationDegrees latitude;
@property CLLocationDegrees longitude;
@property NSString *iconUrlString;
@property NSString *bannerImageUrlString;
@property NSString *bannerColorString;
@property ExploreProjectType type;
@property BOOL joined;
@property NSString *inatDescription;

- (instancetype)initWithMantleModel:(ExploreProject *)model;

+ (NSDictionary *)valueForMantleModel:(ExploreProject *)model;
+ (NSDictionary *)valueForCoreDataModel:(Project *)model;

+ (RLMResults *)joinedProjects;

@end

