//
//  MKMapView+ZoomLevel.m
//  iNaturalist
//
//  via http://stackoverflow.com/questions/7594827/how-to-find-current-zoom-level-of-mkmapview/9275607#9275607
//
//  Created by Alex Shepard on 11/6/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "MKMapView+ZoomLevel.h"

#define MERCATOR_RADIUS 85445659.44705395
#define MAX_GOOGLE_LEVELS 20

@implementation MKMapView (ZoomLevel)

- (double)inat_zoomLevel {
    CLLocationDegrees longitudeDelta = self.region.span.longitudeDelta;
    CGFloat mapWidthInPixels = self.bounds.size.width;
    double zoomScale = longitudeDelta * MERCATOR_RADIUS * M_PI / (180.0 * mapWidthInPixels);
    double zoomer = MAX_GOOGLE_LEVELS - log2( zoomScale );
    if ( zoomer < 0 )
        zoomer = 0;
    return zoomer;
}

@end

