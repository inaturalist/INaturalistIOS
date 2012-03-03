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

#pragma mark - View lifecycle
- (void)viewWillAppear:(BOOL)animated
{
    [self.mapView removeAnnotations:[self.mapView annotations]];
    [self setObservations:[NSMutableArray arrayWithArray:[Observation all]]];
    for (int i = 0; i < self.observations.count; i ++) {
        Observation *obs = [self.observations objectAtIndex:i];
        MKPointAnnotation *anno = [[MKPointAnnotation alloc] init];
        anno.coordinate = CLLocationCoordinate2DMake([obs.latitude doubleValue], [obs.longitude doubleValue]);
        anno.title = [obs speciesGuess];
        anno.subtitle = [obs observedOnPrettyString];
        [self.mapView addAnnotation:anno];
    }
    
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

@end
