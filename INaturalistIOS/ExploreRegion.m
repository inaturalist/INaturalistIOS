//
//  ExploreRegion.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/31/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreRegion.h"

@implementation ExploreRegion

- (instancetype)initWithMKMapRect:(MKMapRect)mapRect {
    if (self = [super init]) {
        MKMapPoint sw = MKMapPointMake(mapRect.origin.x,
                                       mapRect.origin.y + mapRect.size.height);
        self.swCoord = MKCoordinateForMapPoint(sw);

        MKMapPoint ne = MKMapPointMake(mapRect.origin.x + mapRect.size.width,
                                       mapRect.origin.y);
        self.neCoord = MKCoordinateForMapPoint(ne);
    }
    return self;
}

+ (instancetype)regionFromMKMapRect:(MKMapRect)rect {
    return [[ExploreRegion alloc] initWithMKMapRect:rect];
}

@end
