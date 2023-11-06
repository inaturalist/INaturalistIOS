//
//  LocationViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 12/15/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

@import MapKit;

#import "LocationViewController.h"
#import "ObservationVisualization.h"
#import "UIColor+INaturalist.h"
#import "UIImage+MapAnnotations.h"

@interface LocationViewController () <MKMapViewDelegate>
@property IBOutlet MKMapView *mapView;
@end

@implementation LocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CLLocationCoordinate2D coords = [self.observation visibleLocation];
    
    if (CLLocationCoordinate2DIsValid(coords)) {
        // latitude at 90 or -90 is legal on the server, and a legal coordinate,
        // but is super problematic and needs to be nudged.
        // spans with a center latitude at 90 or -90 produce MKCoordinateRegions
        // map distinces of infinity in the x coordinate

        if (coords.latitude == 90) {
            coords = CLLocationCoordinate2DMake(89.999, coords.longitude);
        } else if (coords.latitude == -90) {
            coords = CLLocationCoordinate2DMake(-89.999, coords.longitude);
        }
        
        CLLocationDistance distance;
    	if ([self.observation visiblePositionalAccuracy] == 0) {
    		distance = 500;
    	} else {
    		distance = MAX([self.observation visiblePositionalAccuracy], 200);
    	}
    	
        self.mapView.region = MKCoordinateRegionMakeWithDistance(coords, distance, distance);
        
        MKPointAnnotation *pin = [[MKPointAnnotation alloc] init];
        pin.coordinate = coords;
        pin.title = @"Title";
        [self.mapView addAnnotation:pin];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark MKMapViewDelegate -

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    static NSString *const AnnotationViewReuseID = @"ObservationAnnotationMarkerReuseID";
    
    MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationViewReuseID];
    if (!annotationView) {
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                      reuseIdentifier:AnnotationViewReuseID];
        annotationView.canShowCallout = NO;
    }
    
    annotationView.image = [UIImage annotationImageForObservation:self.observation];
    
    return annotationView;
}

- (void)mapView:(MKMapView *)map didSelectAnnotationView:(MKAnnotationView *)view {
    // do nothing
    return;
}

@end
