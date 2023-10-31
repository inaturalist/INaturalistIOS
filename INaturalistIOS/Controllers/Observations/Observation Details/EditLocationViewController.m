//
//  EditLocationController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/28/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

@import CoreLocation;

#import "EditLocationViewController.h"
#import "CrossHairView.h"
#import "AccuracyCircleView.h"
#import "iNaturalist-Swift.h"
#import "ExploreLocation.h"

@interface EditLocationViewController () <CLLocationManagerDelegate, LocationSearchDelegate> {
    CLLocationManager *_locationManager;
}
@property UISegmentedControl *mapTypeSegmentedControl;
@property (readonly) CLLocationManager *locationManager;
@property (strong, nonatomic) UIBarButtonItem *locationSearchButton;
@end

@implementation EditLocationViewController

#pragma mark - View Controller lifecycle

- (void)dealloc {
    _locationManager.delegate = nil;
    _locationManager = nil;
}
- (void)viewDidLoad
{
    [super viewDidLoad];

    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *navBarApp = [[UINavigationBarAppearance alloc] init];
        [navBarApp configureWithOpaqueBackground];
        navBarApp.backgroundColor = [UIColor whiteColor];
        self.navigationController.navigationBar.standardAppearance = navBarApp;
        self.navigationController.navigationBar.scrollEdgeAppearance = navBarApp;

        UIToolbarAppearance *toolbarApp = [[UIToolbarAppearance alloc] init];
        [toolbarApp configureWithOpaqueBackground];
        toolbarApp.backgroundColor = [UIColor whiteColor];
        self.navigationController.toolbar.standardAppearance = toolbarApp;
        if (@available(iOS 15.0, *)) {
            self.navigationController.toolbar.scrollEdgeAppearance = toolbarApp;
        }
    }


    if (!self.currentLocationButton) {
        self.currentLocationButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"current_location"]
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(clickedCurrentLocationButton)];
        
        self.locationSearchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                                                                  target:self
                                                                                  action:@selector(tappedLocationSearch)];
        [self.currentLocationButton setWidth:30];
    }
    if (!self.mapTypeButton) {
        
        self.mapTypeSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[
                                                                                   @"Standard",
                                                                                   @"Satellite",
                                                                                   @"Hybrid"
                                                                                   ]];
        self.mapTypeSegmentedControl.selectedSegmentIndex = 2;
        [self.mapTypeSegmentedControl addTarget:self
                                         action:@selector(mapTypeChanged:)
                               forControlEvents:UIControlEventValueChanged];
        
        self.mapTypeButton = [[UIBarButtonItem alloc] initWithCustomView:self.mapTypeSegmentedControl];
    }
    
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                          target:nil
                                                                          action:nil];;
    self.toolbarItems = @[ self.currentLocationButton,
                           flex,
                           self.mapTypeButton,
                           flex,
                           self.locationSearchButton];
    
    if (self.currentLocation && self.currentLocation.latitude) {
        double lat = [self.currentLocation.latitude doubleValue];
        double lon = [self.currentLocation.longitude doubleValue];
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(lat, lon);
        if (CLLocationCoordinate2DIsValid(coord)) {
            [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(lat, lon) animated:YES];
            MKCoordinateRegion region;
            region.center.latitude = lat;
            region.center.longitude = lon;
            double meters;
            if (self.currentLocation.accuracy) {
                meters = MAX([self.currentLocation.accuracy longValue], 20);
            } else {
                meters = 500;
                self.currentLocation.accuracy = [NSNumber numberWithInt:meters];
            }
            double accuracyInDegrees = [self metersToDegrees:meters];
            region.span.latitudeDelta = accuracyInDegrees * 5;
            region.span.longitudeDelta = accuracyInDegrees * 5;
            
            // be defensive
            @try {
                [self.mapView setRegion:[self.mapView regionThatFits:region]];
            } @catch (NSException *exception) {
                if ([exception.name isEqualToString:NSInvalidArgumentException]) {
                    // do nothing
                } else {
                    @throw exception;
                }
            }
        } else {
            // null island
            [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(0, 0)];
        }
    } else {
        // null island
        MKCoordinateRegion region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(0,0), MKCoordinateSpanMake(180, 360));
        [self.mapView setRegion:region animated:YES];
    }
    [self updateCrossHair];
    [self updateAccuracyCircle];
    readyToChangeLocation = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setToolbarHidden:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.navigationController setToolbarHidden:YES];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self resetAccuracy];
    [self updateAccuracyCircle];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"MapTypeSegue"]) {
        MapTypeViewController *vc = [segue destinationViewController];
        vc.delegate = self;
        vc.mapType = self.mapView.mapType;
    }
}

#pragma mark - CLLocationManager & helpers

- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    
    return _locationManager;
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    // this location manager requests authorization changes to set user tracking mode
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [self.mapView setUserTrackingMode:MKUserTrackingModeFollow];
            break;
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted: {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Not Allowed", nil)
                                                                           message:NSLocalizedString(@"Location Services Restricted", nil)
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            break;
        }
        case kCLAuthorizationStatusNotDetermined:
        default:
            break;
    }
}

#pragma mark - helpers for accuracy & accuracy circle

- (void)resetAccuracy
{
    CGRect r = self.view.frame;
    double pixelAcc = MIN(r.size.width, r.size.height) / 5;
    self.currentLocation.accuracy = [NSNumber numberWithDouble:[self pixelsToMeters:pixelAcc]];
}

- (void)updateAccuracyCircle
{
    [self.accuracyCircleView setHidden:NO];
    self.accuracyCircleView.radius = [self metersToPixels:[self.currentLocation.accuracy doubleValue]];
    self.accuracyCircleView.label.text = [NSString stringWithFormat:@"Acc: %d m", [self.currentLocation.accuracy intValue]];
}


#pragma mark - setter for currentLocation

- (void)setCurrentLocation:(INatLocation *)currentLocation
{
    _currentLocation = currentLocation;
    if (_currentLocation.latitude) {
        [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake([_currentLocation.latitude doubleValue],
                                                                     [_currentLocation.longitude doubleValue])
                                 animated:YES];
    }
}

#pragma mark - meters / degrees / pixel conversion helpers

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
    double degrees = [self metersToDegrees:meters];
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(self.mapView.centerCoordinate.latitude, self.mapView.centerCoordinate.longitude + degrees);
    CGPoint newPt = [self.mapView convertCoordinate:coord toPointToView:self.mapView];
    return fabs(self.mapView.center.x - newPt.x);
}

- (double)pixelsToMeters:(double)pixels
{
    CLLocationCoordinate2D coord;
    coord = [self.mapView convertPoint:CGPointMake(self.mapView.center.x + pixels, self.mapView.center.y)
                  toCoordinateFromView:self.mapView];
    double distanceInDegrees = fabs(coord.longitude - self.mapView.centerCoordinate.longitude);
    double distanceInMeters = [self degreesToMeters:distanceInDegrees];
    return distanceInMeters;
}

#pragma mark - UIBarButtonItem targets

- (IBAction)clickedCancel:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(editLocationViewControllerDidCancel:)]) {
        [self.delegate performSelector:@selector(editLocationViewControllerDidCancel:) withObject:self];
    }
}

- (IBAction)clickedDone:(id)sender {
    
    if (!self.currentLocation || (self.currentLocation.latitude.integerValue == 0 && self.currentLocation.longitude.integerValue == 0)) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Invalid Location", nil)
                                                                       message:NSLocalizedString(@"Please pick a valid location.", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:nil];
        
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(editLocationViewControllerDidSave:location:)]) {
            [self.delegate performSelector:@selector(editLocationViewControllerDidSave:location:) withObject:self withObject:self.currentLocation];
        }
    }
}

- (void)clickedCurrentLocationButton
{
    if (self.mapView.userTrackingMode == MKUserTrackingModeFollow) {
        [self.mapView setUserTrackingMode:MKUserTrackingModeNone];
    } else {
        switch ([CLLocationManager authorizationStatus]) {
            case kCLAuthorizationStatusAuthorizedAlways:
            case kCLAuthorizationStatusAuthorizedWhenInUse:
                [self.mapView setUserTrackingMode:MKUserTrackingModeFollow];
                break;
            case kCLAuthorizationStatusDenied:
            case kCLAuthorizationStatusRestricted: {
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Not Allowed", nil)
                                                                               message:NSLocalizedString(@"Location Services Restricted", nil)
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];                
                break;
            }
            case kCLAuthorizationStatusNotDetermined:
                [self.locationManager requestWhenInUseAuthorization];
                break;
            default:
                break;
        }
    }
}

- (void)tappedLocationSearch {
    NSLog(@"Search location");
    
    LocationSearchViewController *search = [[LocationSearchViewController alloc] initWithNibName:nil bundle:nil];
    search.locationSearchDelegate = self;
    UINavigationController *searchNav = [[UINavigationController alloc] initWithRootViewController:search];
    
    [self presentViewController:searchNav animated:YES completion:nil];
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

#pragma mark - LocationSearchDelegate

- (void)locationSearchControllerCancelled:(LocationSearchViewController *)search {
    [search dismissViewControllerAnimated:YES completion:nil];
}

- (void)locationSearchController:(LocationSearchViewController *)search choseInatPlace:(ExploreLocation *)location {
    [search dismissViewControllerAnimated:YES completion:nil];
    
    if (MKMapRectIsNull(location.boundingBox)) {
        self.mapView.centerCoordinate = location.location;
    } else {
        [self.mapView setVisibleMapRect:location.boundingBox];
    }
}

- (void)locationSearchController:(LocationSearchViewController *)search chosePlaceMark:(CLPlacemark *)placemark {
    [search dismissViewControllerAnimated:YES completion:nil];
    if (placemark.region && [placemark.region isKindOfClass:CLCircularRegion.class]) {
        CLCircularRegion *circularRegion = (CLCircularRegion *)placemark.region;
        MKCoordinateRegion mapRegion = MKCoordinateRegionMakeWithDistance(circularRegion.center, circularRegion.radius * 2, circularRegion.radius * 2);
        [self.mapView setRegion:mapRegion animated:YES];
    } else if (placemark.location) {
        self.mapView.centerCoordinate = placemark.location.coordinate;
    }
}

# pragma mark - MKMapViewDelegate
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    if (!readyToChangeLocation) {
        return;
    }
    
    if (!self.currentLocation) {
        self.currentLocation = [[INatLocation alloc] init];
    }
    
    BOOL isManuallyEditing = self.mapView.userTrackingMode == MKUserTrackingModeNone;
    
    self.currentLocation.latitude = @(self.mapView.centerCoordinate.latitude);
    self.currentLocation.longitude = @(self.mapView.centerCoordinate.longitude);
    if (!self.accuracyCircleView.hidden && isManuallyEditing) {
        [self resetAccuracy];
    }
    [self updateAccuracyCircle];
    [self updateCrossHair];
    
    self.currentLocation.positioningMethod = mapView.userTrackingMode == MKUserTrackingModeFollow ? @"gps" : @"manual";
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
        self.currentLocationButton.style = UIBarButtonItemStylePlain;
        [self resetAccuracy];
        [self updateAccuracyCircle];
        self.currentLocation.positioningMethod = @"manual";
    }
    [self updateAccuracyCircle];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (mapView.userTrackingMode == MKUserTrackingModeFollow) {
        self.currentLocation.accuracy = [NSNumber numberWithLong:userLocation.location.horizontalAccuracy];
        self.currentLocation.positioningMethod = @"gps";
    } else {
        [self resetAccuracy];
        self.currentLocation.positioningMethod = @"manual";
    }
    [self updateAccuracyCircle];
}

- (void)mapTypeChanged:(UISegmentedControl *)segmentedControl {
    self.mapView.mapType = segmentedControl.selectedSegmentIndex;
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
    return [NSString stringWithFormat:@"<INatLocation: latitude: %@, longitude: %@, accuracy: %@>",
            self.latitude, self.longitude, self.accuracy];
}

@end
