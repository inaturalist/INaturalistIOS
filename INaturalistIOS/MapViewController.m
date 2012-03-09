//
//  MapViewController.m
//  iNaturalist
//
//  Created by Scott Loarie on 2/22/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "MapViewController.h"
#import "Observation.h"
#import "ObservationPhoto.h"
#import "ImageStore.h"
#import "ObservationAnnotation.h"
#import "ObservationDetailViewController.h"
#import <MapKit/MapKit.h>

@interface MapViewController()
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@end

@implementation MapViewController
@synthesize mapView = _mapView;
@synthesize currentLocationButton = _currentLocationButton;
@synthesize mapTypeButton = _mapTypeButton;
@synthesize addObservationButton = _addObservationButton;

- (void)loadObservations
{
    [self.mapView removeAnnotations:[self.mapView annotations]];
    for (Observation *obs in [Observation all]) {
        ObservationAnnotation *anno = [[ObservationAnnotation alloc] initWithObservation:obs];
        [self.mapView addAnnotation:anno];
    }
}

- (void)zoomToObservations
{
    double maxLat = 0, minLat = 0, maxLon = 0, minLon = 0;
    for (ObservationAnnotation *anno in self.mapView.annotations) {
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
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    self.mapView.mapType = MKMapTypeHybrid;
    [self loadObservations];
    [self zoomToObservations];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(loadObservations) 
                                                 name:NSManagedObjectContextDidSaveNotification 
                                               object:[Observation managedObjectContext]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.mapView setShowsUserLocation:YES];
    [self.navigationController.navigationBar setHidden:YES];
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
    if (!self.addObservationButton) {
        self.addObservationButton = [[UIBarButtonItem alloc] initWithTitle:@"Add observation" 
                                                           style:UIBarButtonItemStyleDone 
                                                          target:self
                                                          action:@selector(clickedAddObservationButton)];
        [self.addObservationButton setTintColor:[UIColor colorWithRed:168.0/255 
                                                      green:204.0/255 
                                                       blue:50.0/255 
                                                      alpha:1.0]];
    }
    [self setToolbarItems:[NSArray arrayWithObjects:
                           self.currentLocationButton, 
                           flex, 
                           self.addObservationButton, 
                           flex, 
                           self.mapTypeButton, 
                           nil]];
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.mapView setShowsUserLocation:NO];
    [self.mapView setUserTrackingMode:MKUserTrackingModeNone];
}


- (void)viewDidUnload
{
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
        NSLog(@"clickedCurrentLocationButton, turning off user tracking");
        [self.mapView setUserTrackingMode:MKUserTrackingModeNone];
    } else {
        NSLog(@"clickedCurrentLocationButton, turning ON user tracking");
        [self.mapView setUserTrackingMode:MKUserTrackingModeFollow];
    }
}

- (void)clickedMapTypeButton
{
    [self performSegueWithIdentifier:@"MapTypeSegue" sender:self];
}

- (void)clickedAddObservationButton
{
    [self performSegueWithIdentifier:@"AddObservationSegue" sender:self];
}

# pragma mark - MKMapViewDelegate
- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated
{
    if (mode == MKUserTrackingModeFollow) {
        NSLog(@"didChangeUserTrackingMode, setting button stule to DONE");
        self.currentLocationButton.style = UIBarButtonItemStyleDone;
    } else {
        NSLog(@"didChangeUserTrackingMode, setting button stule to BORDERED");
        self.currentLocationButton.style = UIBarButtonItemStyleBordered;
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    [self performSegueWithIdentifier:@"EditObservationSegue" sender:view];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    // this is actually required if you're going to user user tracking
    if ([annotation class] == MKUserLocation.class) {
        return nil;
    }
    MKPinAnnotationView *av = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:@"ObservationAnnotation"];
    if (!av) {
        av = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"ObservationAnnotation"];
        av.canShowCallout = YES;
        av.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        av.leftCalloutAccessoryView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        av.leftCalloutAccessoryView.contentMode = UIViewContentModeScaleAspectFill;
    }
    ObservationAnnotation *anno = annotation;
    Observation *o = anno.observation;
    UIImageView *iv = (UIImageView *)av.leftCalloutAccessoryView;
    if (o && [o.observationPhotos count] > 0) {
        ObservationPhoto *op = [o.observationPhotos anyObject];
        iv.image = [[ImageStore sharedImageStore] find:op.photoKey forSize:ImageStoreSquareSize];
    } else {
        iv.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:o.iconicTaxonName];
    }
    return av;
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
    } else if ([[segue identifier] isEqualToString:@"AddObservationSegue"]) {
        [self.navigationController.navigationBar setHidden:NO];
        ObservationDetailViewController *vc = [segue destinationViewController];
        [vc setDelegate:self];
        Observation *o = [Observation object];
        o.localObservedOn = [NSDate date];
        [vc setObservation:o];
    } else if ([segue.identifier isEqualToString:@"EditObservationSegue"]) {
        [self.navigationController.navigationBar setHidden:NO];
        ObservationDetailViewController *vc = [segue destinationViewController];
        [vc setDelegate:self];
        MKAnnotationView *av = sender;
        Observation *o = ((ObservationAnnotation *)av.annotation).observation;
        [vc setObservation:o];
    }
}

# pragma mark INObservationDetailViewControllerDelegate methods
- (void)observationDetailViewControllerDidSave:(ObservationDetailViewController *)controller
{
    [self loadObservations];
    [self dismissViewControllerAnimated:YES completion:nil];
    [[self navigationController] popToViewController:self animated:YES];
}

- (void)observationDetailViewControllerDidCancel:(ObservationDetailViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [[self navigationController] popToViewController:self animated:YES];
}

@end
