//
//  ExploreRegion.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/31/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreRegion.h"

@interface ExploreRegion () {
    MKMapRect _mapRect;
}
@end

@implementation ExploreRegion


- (instancetype)initWithMKMapRect:(MKMapRect)mapRect {
    if (self = [super init]) {
        _mapRect = mapRect;
        
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

- (BOOL)isEqualToRegion:(ExploreRegion *)other {
    return self.swCoord.latitude == other.swCoord.latitude &&
            self.swCoord.longitude == other.swCoord.longitude &&
            self.neCoord.latitude == other.neCoord.latitude &&
            self.neCoord.longitude == other.neCoord.longitude;
}

- (MKMapRect)mapRect {
    return _mapRect;
}

- (BOOL)containsCoordinate:(CLLocationCoordinate2D)coord {
    return MKMapRectContainsPoint(self.mapRect, MKMapPointForCoordinate(coord));
}

- (NSString *)description {
    return [NSString stringWithFormat:@"ExploreRegion: SW: %f,%f, NE: %f,%f",
            self.swCoord.latitude, self.swCoord.longitude,
            self.neCoord.latitude, self.neCoord.longitude];
}

@end
