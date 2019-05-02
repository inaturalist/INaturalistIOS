//
//  ExploreProject.h
//  Explore Prototype
//
//  Created by Alex Shepard on 10/2/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <Mantle/Mantle.h>

#import "ProjectVisualization.h"
#import "ExplorePost.h"
#import "ExploreProjectObservationField.h"

typedef NS_ENUM(NSInteger, ExploreProjectType) {
    ExploreProjectTypeCollection,
    ExploreProjectTypeUmbrella,
    ExploreProjectTypeOldStyle
};

@interface ExploreProjectSiteFeatures: MTLModel <MTLJSONSerializing>
@property (nonatomic, assign) NSInteger siteId;
@property (nonatomic, copy) NSDate *featuredAt;
@end

@interface ExploreProject : MTLModel <MTLJSONSerializing, ProjectVisualization>

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *inatDescription;
@property (nonatomic, assign) NSInteger projectId;
@property (nonatomic, assign) NSInteger locationId;
@property (nonatomic, assign) CLLocationDegrees latitude;
@property (nonatomic, assign) CLLocationDegrees longitude;
@property (nonatomic, copy) NSURL *iconUrl;
@property (nonatomic, copy) NSString *terms;
@property (nonatomic) NSArray <ExploreProjectSiteFeatures *> *siteFeatures;
@property (nonatomic) NSArray <ExplorePost *> *posts;
@property (nonatomic, assign) ExploreProjectType type;
@property (nonatomic) NSArray <ExploreProjectObservationField *> *fields;

@property (readonly) NSArray <ExploreProjectObservationField *> *requiredFields;

@end
