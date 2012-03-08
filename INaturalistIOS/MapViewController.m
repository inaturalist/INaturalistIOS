//
//  MapViewController.m
//  INaturalistIOS
//
//  Created by Scott Loarie on 2/22/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "MapViewController.h"
#import "Observation.h"
#import "ObservationPhoto.h"
#import "ImageStore.h"
#import <MapKit/MapKit.h>

@interface MapViewController()
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@end

@implementation MapViewController
@synthesize mapView = _mapView;
@synthesize observations = _observations;
@synthesize currentLocationButton = _currentLocationButton;
@synthesize mapTypeButton = _mapTypeButton;

- (void)viewDidLoad
{
    self.mapView.mapType = MKMapTypeHybrid;
}

#pragma mark - View lifecycle
- (void)viewWillAppear:(BOOL)animated
{
    [self.mapView removeAnnotations:[self.mapView annotations]];
    [self setObservations:[NSMutableArray arrayWithArray:[Observation all]]];
    double maxLat = 0, minLat = 0, maxLon = 0, minLon = 0;
    for (int i = 0; i < self.observations.count; i ++) {
        Observation *obs = [self.observations objectAtIndex:i];
        MKPointAnnotation *anno = [[MKPointAnnotation alloc] init];
        anno.coordinate = CLLocationCoordinate2DMake([obs.latitude doubleValue], 
                                                     [obs.longitude doubleValue]);
        anno.title = obs.speciesGuess && obs.speciesGuess.length > 0 ? obs.speciesGuess : @"Something...";
        anno.subtitle = [obs observedOnPrettyString];
        [self.mapView addAnnotation:anno];
        minLat = minLat == 0 || anno.coordinate.latitude  < minLat ? anno.coordinate.latitude  : minLat;
        minLon = minLon == 0 || anno.coordinate.longitude < minLon ? anno.coordinate.longitude : minLon;
        maxLat = maxLat == 0 || anno.coordinate.latitude  > maxLat ? anno.coordinate.latitude  : maxLat;
        maxLon = maxLon == 0 || anno.coordinate.longitude > maxLon ? anno.coordinate.longitude : maxLon;
    }
    
    MKCoordinateRegion region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(minLat + (maxLat - minLat) / 2.0, 
                                                                                  minLon + (maxLon - minLon) / 2.0), 
                                                       MKCoordinateSpanMake(fabs(maxLat - minLat), 
                                                                            fabs(maxLon - minLon)));
    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:NO];
    
    [self.navigationController setToolbarHidden:NO];
    [[[self navigationController] toolbar] setBarStyle:UIBarStyleBlack];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    if (!self.currentLocationButton) {
        self.currentLocationButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"current_location.png"]
                                                                      style:UIBarButtonItemStyleBordered 
                                                                     target:self 
                                                                     action:@selector(clickedCurrentLocationButton)];
        [self.currentLocationButton setWidth:30];
    }
    if (!self.mapTypeButton) {
        self.mapTypeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPageCurl 
                                                                           target:self 
                                                                           action:@selector(clickedMapTypeButton)];
    }
    [self setToolbarItems:[NSArray arrayWithObjects:self.currentLocationButton, flex, self.mapTypeButton, nil]];
    
    [super viewWillAppear:animated];
}

// This doesn't quite work yet, I think b/c the annotations in mapView.annotations aren't kept in the order they're added.  
// Probably need to sublcass MKPointAnnotation to hold a ref to the observation
//- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
//{
//    MKPinAnnotationView *av = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:@"ObservationAnnotation"];
//    if (!av) {
//        av = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"ObservationAnnotation"];
//        av.canShowCallout = YES;
//    }
//    Observation *o = [self.observations objectAtIndex:[self.mapView.annotations indexOfObject:annotation]];
//    if (o && [o.observationPhotos count] > 0) {
//        ObservationPhoto *op = [o.observationPhotos anyObject];
//        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
//        iv.image = [[ImageStore sharedImageStore] find:op.photoKey forSize:ImageStoreSquareSize];
//        iv.contentMode = UIViewContentModeScaleAspectFill;
//        av.leftCalloutAccessoryView = iv;
//    } else {
//        av.leftCalloutAccessoryView = nil;
//    }
//    return av;
//}


- (void)viewDidUnload
{
    self.observations = nil;
    [self.mapView removeAnnotations:self.mapView.annotations];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)clickedCurrentLocationButton
{
    if (self.mapView.userTrackingMode == MKUserTrackingModeFollow) {
        [self.mapView setUserTrackingMode:MKUserTrackingModeNone];
    } else {
        [self.mapView setUserTrackingMode:MKUserTrackingModeFollow];
    }
}

- (void)clickedMapTypeButton
{
    [self performSegueWithIdentifier:@"MapTypeSegue" sender:self];
}

# pragma mark - MKMapViewDelegate
- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated
{
    if (mode == MKUserTrackingModeFollow) {
        self.currentLocationButton.style = UIBarButtonItemStyleDone;
    } else {
        self.currentLocationButton.style = UIBarButtonItemStyleBordered;
    }
}


# pragma mark MapTypeViewControllerDelegate
- (void)mapTypeControllerDidChange:(MapTypeViewController *)controller mapType:(NSNumber *)mapType
{
    self.mapView.mapType = mapType.intValue;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"MapTypeSegue"]) {
        MapTypeViewController *vc = [segue destinationViewController];
        vc.delegate = self;
        vc.mapType = self.mapView.mapType;
    }
}

@end
