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

@interface ExploreProject : MTLModel <MTLJSONSerializing, ProjectVisualization>

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) NSInteger projectId;
@property (nonatomic, assign) NSInteger locationId;
@property (nonatomic, assign) CLLocationDegrees latitude;
@property (nonatomic, assign) CLLocationDegrees longitude;
@property (nonatomic, copy) NSURL *iconUrl;
@property (nonatomic, copy) NSURL *bannerImageUrl;
@property (nonatomic, copy) NSString *bannerColorString;
@property (nonatomic, assign) ExploreProjectType type;
@property (nonatomic, copy) NSString *inatDescription;

@property (nonatomic, copy) NSArray *projectObsFields;
@property (readonly) NSArray *sortedProjectObsFields;

@end
