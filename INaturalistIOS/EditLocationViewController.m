//
//  EditLocationController.m
//  INaturalistIOS
//
//  Created by Ken-ichi Ueda on 2/28/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "EditLocationViewController.h"
#import "CrossHairView.h"
#import "AccuracyCircleView.h"

@implementation EditLocationViewController
@synthesize mapView = _mapView;
@synthesize delegate = _delegate;
@synthesize currentLocation = _currentLocation;
@synthesize currentLocationButton = _currentLocationButton;
@synthesize mapTypeButton = _mapTypeButton;
@synthesize crossHairView = _crossHairView;
@synthesize accuracyCircleView = _accuracyCircleView;

#pragma mark - View lifecycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateCrossHair];
    [self updateAccuracyCircle];
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
    if (self.currentLocation && self.currentLocation.latitude) {
        double lat = [self.currentLocation.latitude doubleValue];
        double lon = [self.currentLocation.longitude doubleValue];
        [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(lat, lon) animated:YES];
        MKCoordinateRegion region;
        region.center.latitude = lat;
        region.center.longitude = lon;
        if (self.currentLocation && self.currentLocation.accuracy) {
            double accuracyInDegrees = [self metersToDegrees:[self.currentLocation.accuracy longValue]];
            region.span.latitudeDelta = accuracyInDegrees * 5;
            region.span.longitudeDelta = accuracyInDegrees * 5;
        } else {
            region.span.latitudeDelta = 1;
            region.span.longitudeDelta = 1;
        }
        [self.mapView setRegion:[self.mapView regionThatFits:region]];
        [self updateAccuracyCircle];
    }
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [self setMapView:nil];
    [self setMapTypeButton:nil];
    [self setCrossHairView:nil];
    [self setAccuracyCircleView:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (INatLocation *)currentLocation
{
    if (!_currentLocation) {
        _currentLocation = [[INatLocation alloc] initWithLatitude:[NSNumber numberWithDouble:self.mapView.centerCoordinate.latitude]
                                                        longitude:[NSNumber numberWithDouble:self.mapView.centerCoordinate.longitude]
                                                         accuracy:nil];
    }
    return _currentLocation;
}

- (void)setCurrentLocation:(INatLocation *)currentLocation
{
    _currentLocation = currentLocation;
    if (_currentLocation.latitude) {
        [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake([_currentLocation.latitude doubleValue],
                                                                     [_currentLocation.longitude doubleValue])
                                 animated:YES];
    }
}

- (double)degreesToMeters:(double)degrees
{
    double planetaryRadius = 6370997.0;
    return degrees * 2 * M_PI * planetaryRadius / 360.0;
}

- (double)metersToDegrees:(double)meters
{
    double planetaryRadius = 6370997.0;
    return meters * 360.0 / (2 * M_PI * planetaryRadius);
}

- (double)metersToPixels:(double)meters
{
    MKCoordinateRegion r = MKCoordinateRegionMakeWithDistance(self.mapView.centerCoordinate, meters, meters);
    return [self.mapView convertRegion:r toRectToView:nil].size.width;
}

- (double)pixelsToMeters:(double)pixels
{
    CLLocationCoordinate2D coord = [self.mapView convertPoint:CGPointMake(self.mapView.center.x + pixels, self.mapView.center.y) 
                                         toCoordinateFromView:nil];
    return [self degreesToMeters:fabs(coord.latitude - self.mapView.centerCoordinate.latitude)];

}

- (IBAction)clickedCancel:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(editLocationViewControllerDidCancel:)]) {
        [self.delegate performSelector:@selector(editLocationViewControllerDidCancel) withObject:self];
    }
    [[self parentViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)clickedDone:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(editLocationViewControllerDidSave:location:)]) {
        [self.delegate performSelector:@selector(editLocationViewControllerDidSave:location:) withObject:self withObject:self.currentLocation];
    }
    [[self parentViewController] dismissViewControllerAnimated:YES completion:nil];
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

- (void)updateCrossHair
{
    self.crossHairView.xLabel.text = [NSString stringWithFormat:@"Lon: %f", self.mapView.centerCoordinate.longitude];
    self.crossHairView.yLabel.text = [NSString stringWithFormat:@"Lat: %f", self.mapView.centerCoordinate.latitude];
}

# pragma mark - MKMapViewDelegate
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    if (self.currentLocation && [self.currentLocation.updatedAt timeIntervalSinceNow] < -1) {
        self.currentLocation.latitude = [NSNumber numberWithDouble:self.mapView.centerCoordinate.latitude];
        self.currentLocation.longitude = [NSNumber numberWithDouble:self.mapView.centerCoordinate.longitude];
        if (!self.accuracyCircleView.hidden && self.mapView.userTrackingMode == MKUserTrackingModeNone) {
            self.currentLocation.accuracy = [NSNumber numberWithDouble:[self pixelsToMeters:self.accuracyCircleView.radius]];
        }
        [self updateAccuracyCircle];
        [self updateCrossHair];
        
        self.currentLocation.positioningMethod = mapView.userTrackingMode == MKUserTrackingModeFollow ? @"gps" : @"manual";
    }
}

- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated
{
    if (mode == MKUserTrackingModeFollow) {
        self.currentLocationButton.style = UIBarButtonItemStyleDone;
        self.currentLocation.latitude = [NSNumber numberWithDouble:self.mapView.userLocation.location.coordinate.latitude];
        self.currentLocation.longitude = [NSNumber numberWithDouble:self.mapView.userLocation.location.coordinate.longitude];
        self.currentLocation.accuracy = [NSNumber numberWithDouble:self.mapView.userLocation.location.horizontalAccuracy];
        self.currentLocation.positioningMethod = @"gps";
    } else {
        self.currentLocationButton.style = UIBarButtonItemStyleBordered;
        self.currentLocation.accuracy = [NSNumber numberWithDouble:[self pixelsToMeters:self.view.bounds.size.width / 8.0]];
        self.currentLocation.positioningMethod = @"manual";
    }
    [self updateAccuracyCircle];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (mapView.userTrackingMode == MKUserTrackingModeFollow) {
        self.currentLocation.accuracy = [NSNumber numberWithLong:userLocation.location.horizontalAccuracy];
        [self updateAccuracyCircle];
        self.currentLocation.positioningMethod = @"gps";
    } else {
        self.currentLocation.accuracy = nil;
        self.currentLocation.positioningMethod = @"manual";
    }
}

# pragma mark MapTypeViewControllerDelegate
- (void)mapTypeControllerDidChange:(MapTypeViewController *)controller mapType:(NSNumber *)mapType
{
    self.mapView.mapType = mapType.intValue;
}

- (void)updateAccuracyCircle
{
    if (!self.currentLocation || !self.currentLocation.accuracy) {
        [self.accuracyCircleView setHidden:YES];
    } else {
        [self.accuracyCircleView setHidden:NO];
        self.accuracyCircleView.radius = [self metersToPixels:[self.currentLocation.accuracy doubleValue]];
        self.accuracyCircleView.label.text = [NSString stringWithFormat:@"Acc: %d m", [self.currentLocation.accuracy longValue]];
    }
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

@implementation INatLocation
@synthesize latitude = _latitude;
@synthesize longitude = _longitude;
@synthesize accuracy = _accuracy;
@synthesize updatedAt = _updatedAt;
@synthesize positioningMethod = _positioningMethod;

- (id)initWithLatitude:(NSNumber *)latitude longitude:(NSNumber *)longitude accuracy:(NSNumber *)accuracy
{
    self = [super init];
    if (self) {
        self.latitude = latitude;
        self.longitude = longitude;
        self.accuracy = accuracy;
    }
    return self;
}

- (void)setLatitude:(NSNumber *)latitude
{
    _latitude = latitude;
    self.updatedAt = [NSDate date];
}

- (void)setLongitude:(NSNumber *)longitude
{
    _longitude = longitude;
    self.updatedAt = [NSDate date];
}

- (void)setAccuracy:(NSNumber *)accuracy
{
    if ([accuracy intValue] != 0) {
        _accuracy = accuracy;
        self.updatedAt = [NSDate date];
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<INatLocation: lat: %@ lon:%@ acc:%@>", self.latitude, self.longitude, self.accuracy];
}

@end
