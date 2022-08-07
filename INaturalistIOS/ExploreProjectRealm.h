//
//  ExploreProjectRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 1/6/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>

#import "ExploreProject.h"
#import "ProjectVisualization.h"
#import "ExploreProjectObsFieldRealm.h"

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
@property NSString *inatDescription;

- (BOOL)isNewStyleProject;

- (instancetype)initWithMantleModel:(ExploreProject *)model;

// to-many relationships
@property RLMArray<ExploreProjectObsFieldRealm *><ExploreProjectObsFieldRealm> *projectObsFields;

+ (NSDictionary *)valueForMantleModel:(ExploreProject *)model;
+ (NSDictionary *)valueForCoreDataModel:(id)model;

- (NSString *)titleForTypeOfProject;


@end

RLM_COLLECTION_TYPE(ExploreProjectRealm)

