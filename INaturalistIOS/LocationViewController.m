//
//  LocationViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 12/15/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

@import MapKit;

#import <FontAwesomeKit/FAKIonIcons.h>

#import "LocationViewController.h"
#import "ObservationVisualization.h"
#import "UIColor+INaturalist.h"
#import "UIColor+ExploreColors.h"

@interface LocationViewController () <MKMapViewDelegate>
@property IBOutlet MKMapView *mapView;
@end

@implementation LocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CLLocationCoordinate2D coords = [self.observation visibleLocation];
    
    if (CLLocationCoordinate2DIsValid(coords)) {
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
    
    // style for iconic taxon of the observation
    FAKIcon *mapMarker = [FAKIonIcons iosLocationIconWithSize:35.0f];
    [mapMarker addAttribute:NSForegroundColorAttributeName value:[UIColor colorForIconicTaxon:self.observation.iconicTaxonName]];
    FAKIcon *mapOutline = [FAKIonIcons iosLocationOutlineIconWithSize:35.0f];
    [mapOutline addAttribute:NSForegroundColorAttributeName value:[[UIColor colorForIconicTaxon:self.observation.iconicTaxonName] darkerColor]];
    
    // offset the marker so that the point of the pin (rather than the center of the glyph) is at the location of the observation
    [mapMarker addAttribute:NSBaselineOffsetAttributeName value:@(35.0f)];
    [mapOutline addAttribute:NSBaselineOffsetAttributeName value:@(35.0f)];
    annotationView.image = [UIImage imageWithStackedIcons:@[mapMarker, mapOutline] imageSize:CGSizeMake(35.0f, 70)];
    
    return annotationView;
}

- (void)mapView:(MKMapView *)map didSelectAnnotationView:(MKAnnotationView *)view {
    // do nothing
    return;
}

@end
