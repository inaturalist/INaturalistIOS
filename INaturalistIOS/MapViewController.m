//
//  MapViewController.m
//  INaturalistIOS
//
//  Created by Scott Loarie on 2/22/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "MapViewController.h"
#import "Observation.h"
#import <MapKit/MapKit.h>
@interface MapViewController()
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@end

@implementation MapViewController
@synthesize mapView = _mapView;
@synthesize observations = _observations;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle
/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setObservations:[[NSMutableArray alloc] initWithArray:[Observation all]]];
    for (Observation *obs in self.observations) {
        CLLocationCoordinate2D annotationCoord;
        annotationCoord.latitude = [[NSNumber numberWithInt:rand() % 89] doubleValue];
        annotationCoord.longitude = [[NSNumber numberWithInt:rand() % 179] doubleValue];
        
        MKPointAnnotation *annotationPoint = [[MKPointAnnotation alloc] init];
        annotationPoint.coordinate = annotationCoord;
        annotationPoint.title = [obs species_guess];
        annotationPoint.subtitle = [obs observed_on_string];
        [self.mapView addAnnotation:annotationPoint]; 
    }
}


- (void)viewDidUnload
{
    [self setMapView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
