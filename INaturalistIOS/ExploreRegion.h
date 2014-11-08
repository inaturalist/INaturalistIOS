//
//  ExploreRegion.h
//  iNaturalist
//
//  Created by Alex Shepard on 10/31/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface ExploreRegion : NSObject

@property CLLocationCoordinate2D swCoord;
@property CLLocationCoordinate2D neCoord;
@property (readonly) MKMapRect mapRect;

+ (instancetype)regionFromMKMapRect:(MKMapRect)rect;

- (BOOL)isEqualToRegion:(ExploreRegion *)other;

- (BOOL)containsCoordinate:(CLLocationCoordinate2D)coord;

@end
