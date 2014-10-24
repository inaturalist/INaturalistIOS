//
//  ExploreMapViewController.m
//  Explore Prototype
//
//  Created by Alex Shepard on 9/12/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

#import <RestKit/RestKit.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/UIBarButtonItem+BlocksKit.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <GeoJSONSerialization/GeoJSONSerialization.h>
#import <FlurrySDK/Flurry.h>

#import "ExploreMapViewController.h"
#import "ExploreMappingProvider.h"
#import "ExploreLocation.h"
#import "ExploreObservationDetailViewController.h"
#import "ExploreProject.h"
#import "UIColor+ExploreColors.h"

@interface ExploreMapViewController () <MKMapViewDelegate, CLLocationManagerDelegate> {
    ExploreLocation *centerLocation;
    
    MKMapView *mapView;
    
    BOOL isTrackingUserLocation;
    
    CLLocationManager *locationManager;
}

@end

@implementation ExploreMapViewController

#pragma mark UIViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {

    }
    
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [Flurry logEvent:@"Navigate - Explore Map" timed:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [Flurry endTimedEvent:@"Navigate - Explore Map" withParameters:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    //[self stopShowingUserLocation];
}

- (void)viewDidUnload {
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    mapView = ({
        // use autolayout
        MKMapView *map = [[MKMapView alloc] initWithFrame:CGRectZero];
        map.translatesAutoresizingMaskIntoConstraints = NO;
        
        map.mapType = MKMapTypeHybrid;
        map.delegate = self;
        
        map;
    });
    [self.view addSubview:mapView];
    
    NSDictionary *views = @{
                            @"bottomLayoutGuide": self.bottomLayoutGuide,
                            @"mapView": mapView,
                            };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[mapView]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[mapView]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
}

#pragma mark - KVO

- (void)observationChangedCallback {
    [mapView removeAnnotations:mapView.annotations];
    [mapView addAnnotations:self.observationDataSource.mappableObservations];
    
    // scroll to fit the new annotations
    [mapView showAnnotations:self.observationDataSource.mappableObservations animated:YES];
    
    [mapView removeOverlays:mapView.overlays];
    if ([self.observationDataSource activeSearchLimitedByLocation]) {
        for (ExploreSearchPredicate *predicate in self.observationDataSource.activeSearchPredicates) {
            if (predicate.type == ExploreSearchPredicateTypePlace)
                [self addOverlaysForLocationId:predicate.searchLocation.locationId];
            else if (predicate.type == ExploreSearchPredicateTypeProject)
                [self addOverlaysForLocationId:predicate.searchProject.locationId];
        }
    }
}

#pragma mark - CLLocationManagerDelegate

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusNotDetermined:
            return;
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            //[self showUserLocation];
            break;
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted:
            [[[UIAlertView alloc] initWithTitle:@"Permission denied"
                                        message:@"We don't have permission from iOS to use your location."
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        default:
            break;
    }
}

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mv regionDidChangeAnimated:(BOOL)animated {
    // inifinite scroll into new region
    /*
    self.observationDataSource.rect = mv.visibleMapRect;
    [self.observationDataSource fetchObservations];
     */
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    MKPolygonRenderer *renderer = [[MKPolygonRenderer alloc] initWithOverlay:overlay];
    renderer.alpha = 1.0f;
    renderer.lineWidth = 2.0f;
    renderer.strokeColor = [[UIColor inatGreen] colorWithAlphaComponent:1.0f];
    renderer.fillColor = [[UIColor inatGreen] colorWithAlphaComponent:0.2f];
    return renderer;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    ExploreObservationDetailViewController *detail = [[ExploreObservationDetailViewController alloc] initWithNibName:nil bundle:nil];
    detail.observation = (ExploreObservation *)view.annotation;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:detail];
    
    // close icon
    FAKIcon *closeIcon = [FAKIonIcons ios7CloseEmptyIconWithSize:34.0f];
    [closeIcon addAttribute:NSForegroundColorAttributeName value:[UIColor inatGreen]];
    UIImage *closeImage = [closeIcon imageWithSize:CGSizeMake(25.0f, 34.0f)];
    
    UIBarButtonItem *close = [[UIBarButtonItem alloc] bk_initWithImage:closeImage
                                                                 style:UIBarButtonItemStylePlain
                                                               handler:^(id sender) {
                                                                   [self dismissViewControllerAnimated:YES completion:nil];
                                                               }];
    
    detail.navigationItem.leftBarButtonItem = close;
    
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - iNat API Calls

- (void)addOverlaysForLocationId:(NSInteger)locationId {
    // fetch the geometry file
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.inaturalist.org/places/geometry/%ld.geojson",
                                       (long)locationId]];
    NSData *data = [NSData dataWithContentsOfURL:URL];
    
    // don't do any overlay work if we can't get a geometry file from inat.org
    if (!data)
        return;
    
    // add
    [self addShapesFromGeoJSONData:data toMap:mapView];
}


#pragma mark - MapKit Helpers

// helper for adding a shape from a geojson object
- (void)addShapesFromGeoJSONData:(NSData *)data toMap:(MKMapView *)map {
    NSError *error;
    
    // deserialize json from NSData into an NSDictionary
    NSDictionary *geoJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error) {
        NSLog(@"error deserializing json from data: %@", error.localizedDescription);
        return;
    }
    
    // GeoJSONSerialization expects the shape(s) to be encapsulated in a "Feature' object
    NSDictionary *dict = @{ @"type": @"Feature",
                            @"geometry": geoJSON };
    
    // deserialize the geojson NSDictionary into a shape
    id shape = [GeoJSONSerialization shapeFromGeoJSONFeature:dict error:&error];
    if (error) {
        NSLog(@"error deserializing MapKit shape from GeoJSON: %@", error.localizedDescription);
        return;
    }
    
    if ([shape isKindOfClass:[NSArray class]]) {
        // some geometries contain multiple shapes (ie San Francisco County)
        for (id each in (NSArray *)shape) {
            if ([each conformsToProtocol:@protocol(MKOverlay)]) {
                [map addOverlay:(id <MKOverlay>)each];
            } else {
                NSLog(@"warning: got a non MKOverlay object: %@", each);
            }
        }
    } else if ([shape conformsToProtocol:@protocol(MKOverlay)]) {
        [map addOverlay:(id <MKOverlay>)shape];
        [map setVisibleMapRect:((id <MKOverlay>)shape).boundingMapRect animated:YES];
    } else {
        NSLog(@"warning: got a non MKOverlay object: %@", shape);
    }
}

#pragma mark - ExploreViewControllerControlIcon

- (UIImage *)controlIcon {
    FAKIcon *map = [FAKIonIcons mapIconWithSize:22.0f];
    [map addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
    return [map imageWithSize:CGSizeMake(25.0f, 25.0f)];
}

@end
