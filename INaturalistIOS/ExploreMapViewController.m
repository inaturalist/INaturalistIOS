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

#import "ExploreMapViewController.h"
#import "ExploreMappingProvider.h"
#import "ExploreLocation.h"
#import "ExploreObservationDetailViewController.h"
#import "ExploreProject.h"
#import "UIColor+ExploreColors.h"
#import "Analytics.h"
#import "ExploreObservation.h"
#import "ExploreRegion.h"

@interface ExploreMapViewController () <MKMapViewDelegate, CLLocationManagerDelegate> {
    ExploreLocation *centerLocation;
    
    MKMapView *mapView;
    
    BOOL isTrackingUserLocation;
    
    CLLocationManager *locationManager;
    
    NSTimer *mapChangedTimer;
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
    
    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateExploreMap];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateExploreMap];
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
                            @"mapView": mapView,
                            };
    
    NSDictionary *metrics = @{
                              @"topLayoutGuideLength": @(self.parentViewController.topLayoutGuide.length),
                              @"bottomLayoutGuideLength": @(self.parentViewController.bottomLayoutGuide.length),
                              };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[mapView]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-topLayoutGuideLength-[mapView]-bottomLayoutGuideLength-|"
                                                                      options:0
                                                                      metrics:metrics
                                                                        views:views]];
}

#pragma mark - KVO

- (void)observationChangedCallback {
    // in case this callback fires because of a change in search,
    // invalidate the map changed timer. unlikely but be safe.
    [mapChangedTimer invalidate];
    
    if (self.observationDataSource.latestSearchShouldResetUI) {
        [mapView removeAnnotations:mapView.annotations];
        [mapView removeOverlays:mapView.overlays];
        
        // when the user has caused this latest fetch, we want to show just the 100 most recent
        [mapView removeAnnotations:mapView.annotations];
        NSArray *recent = [self.observationDataSource.mappableObservations bk_select:^BOOL(id obj) {
            return [self.observationDataSource.mappableObservations indexOfObject:obj] < 100;
        }];
        [mapView addAnnotations:recent];
        [mapView showAnnotations:mapView.annotations animated:YES];
        
        // if necessary, add an overlay
        if ([self.observationDataSource activeSearchLimitedByLocation] && mapView.overlays.count == 0) {
            for (ExploreSearchPredicate *predicate in self.observationDataSource.activeSearchPredicates) {
                if (predicate.type == ExploreSearchPredicateTypePlace) {
                    [self addOverlaysForLocationId:predicate.searchLocation.locationId];
                    // prefer places for overlays
                    break;
                } else if (predicate.type == ExploreSearchPredicateTypeProject) {
                    if (predicate.searchProject.locationId != 0)
                        [self addOverlaysForLocationId:predicate.searchProject.locationId];
                }
            }
        }
    } else {
        // try to be smart about updating the visible annotations
        // sweep through and remove any annotations that aren't in the visible map rect anymore
        [mapView removeAnnotations:[mapView.annotations bk_select:^BOOL(id <MKAnnotation> annotation) {
            return !MKMapRectContainsPoint(mapView.visibleMapRect, MKMapPointForCoordinate(annotation.coordinate));
        }]];
        
        // compile candidates for adding to the map
        NSArray *sortedCandidates = [self.observationDataSource.mappableObservations bk_select:^BOOL(ExploreObservation *candidate) {
            return MKMapRectContainsPoint(mapView.visibleMapRect, MKMapPointForCoordinate(candidate.coordinate));
        }];
        
        // remove anything that's not in candidates, or that's not in the first 100
        NSArray *annotationsToRemove = [mapView.annotations bk_select:^BOOL(id obj) {
            return [sortedCandidates containsObject:obj] && [sortedCandidates indexOfObject:obj] >= 100;
        }];
        [mapView removeAnnotations:annotationsToRemove];
        
        // add anything that's in candidates but not on the map already, and that's in the first 100
        NSArray *annotationsToAdd = [sortedCandidates bk_select:^BOOL(id obj) {
            return ![mapView.annotations containsObject:obj] && [sortedCandidates indexOfObject:obj] < 100;
        }];
        
        [mapView addAnnotations:annotationsToAdd];
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

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    //[mapChangedTimer invalidate];
}

- (void)mapView:(MKMapView *)mv regionDidChangeAnimated:(BOOL)animated {
    if ([mapChangedTimer isValid]) {
        // already something queued up
        return;
    }
    
    // give the user a bit to keep scrolling before we make a new API call
    mapChangedTimer = [NSTimer bk_scheduledTimerWithTimeInterval:0.75f
                                                           block:^(NSTimer *timer) {
                                                               // inifinite scroll into new region
                                                               ExploreRegion *region = [ExploreRegion regionFromMKMapRect:mv.visibleMapRect];
                                                               [self.observationDataSource expandActiveSearchIntoLocationRegion:region];
                                                           }
                                                         repeats:NO];
}

- (MKAnnotationView *)mapView:(MKMapView *)map viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    static NSString *const AnnotationViewReuseID = @"ObservationAnnotationMarkerReuseID";
    
    MKAnnotationView *annotationView = [map dequeueReusableAnnotationViewWithIdentifier:AnnotationViewReuseID];
    if (!annotationView) {
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                       reuseIdentifier:AnnotationViewReuseID];
        annotationView.canShowCallout = NO;
    }
    
    // style for iconic taxon of the observation
    FAKIcon *mapMarker = [FAKIonIcons ios7LocationIconWithSize:25.0f];
    ExploreObservation *observation = (ExploreObservation *)annotation;
    [mapMarker addAttribute:NSForegroundColorAttributeName value:[UIColor colorForIconicTaxon:observation.iconicTaxonName]];
    FAKIcon *mapOutline = [FAKIonIcons ios7LocationOutlineIconWithSize:25.0f];
    [mapOutline addAttribute:NSForegroundColorAttributeName value:[[UIColor colorForIconicTaxon:observation.iconicTaxonName] darkerColor]];
    annotationView.image = [UIImage imageWithStackedIcons:@[mapMarker, mapOutline] imageSize:CGSizeMake(25.0f, 25.0f)];
    
    
    return annotationView;
}


- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    MKPolygonRenderer *renderer = [[MKPolygonRenderer alloc] initWithOverlay:overlay];
    renderer.alpha = 1.0f;
    renderer.lineWidth = 2.0f;
    renderer.strokeColor = [[UIColor mapOverlayColor] colorWithAlphaComponent:1.0f];
    renderer.fillColor = [[UIColor mapOverlayColor] colorWithAlphaComponent:0.2f];
    return renderer;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    // deselect the annotation so the user can select it again
    [mapView deselectAnnotation:view.annotation animated:NO];
    
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
