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

@interface ExploreProject : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) NSInteger projectId;
@property (nonatomic, assign) NSInteger locationId;
@property (nonatomic, assign) CLLocationDegrees latitude;
@property (nonatomic, assign) CLLocationDegrees longitude;
@property (nonatomic, copy) NSString *iconUrl;

@end
