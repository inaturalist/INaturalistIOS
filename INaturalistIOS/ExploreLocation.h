//
//  ExploreLocation.h
//  Explore Prototype
//
//  Created by Alex Shepard on 10/1/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface ExploreLocation : NSObject

@property (nonatomic, assign) NSInteger locationId;
@property (nonatomic, assign) NSInteger type;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) CLLocationDegrees latitude;
@property (nonatomic, assign) CLLocationDegrees longitude;
@property (nonatomic, copy) NSNumber *adminLevel;
@property (nonatomic, copy) NSString *placeTypeName;

@end
