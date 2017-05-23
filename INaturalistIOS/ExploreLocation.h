//
//  ExploreLocation.h
//  Explore Prototype
//
//  Created by Alex Shepard on 10/1/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@import CoreLocation;
@import MapKit;

@interface ExploreLocation : MTLModel <MTLJSONSerializing>

@property (nonatomic, assign) NSInteger locationId;
@property (nonatomic, assign) NSInteger type;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) CLLocationCoordinate2D location;
@property (nonatomic, copy) NSNumber *adminLevel;
@property (nonatomic, assign) CLLocationCoordinate2D boundingBoxOrigin;
@property (nonatomic, assign) CGSize boundingBoxCGSize;

@property (nonatomic, assign) MKMapRect boundingBox;

@end
