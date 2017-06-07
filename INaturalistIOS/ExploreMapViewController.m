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
#import "ExploreLocation.h"
#import "ExploreProject.h"
#import "UIColor+ExploreColors.h"
#import "Analytics.h"
#import "ExploreObservation.h"
#import "ExploreRegion.h"
#import "MKMapView+ZoomLevel.h"
#import "NSURL+INaturalist.h"
#import "ExploreContainerViewController.h"
#import "ObsDetailV2ViewController.h"

@interface ExploreMapViewController () <MKMapViewDelegate, CLLocationManagerDelegate> {
    ExploreLocation *centerLocation;
    MKMapView *mapView;
    NSTimer *mapChangedTimer;
    BOOL mapViewHasRenderedTiles;
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
    
    // make sure we are really and truly on top
    // this is fragile and assumes this VC will only be used in the app in this view hierarchy
    if ([self.tabBarController.selectedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *topNav = (UINavigationController *)self.tabBarController.selectedViewController;
        if ([topNav.topViewController isKindOfClass:[ExploreContainerViewController class]]) {
            ExploreContainerViewController *container = (ExploreContainerViewController *)topNav.topViewController;
            if (container.selectedViewController == self) {
                
                // if the limiting region was cleared, then re-apply it once the map returns
                // avoid doing this if the map hasn't rendered at least once (ie a fresh launch)
                if (!self.observationDataSource.limitingRegion && mapViewHasRenderedTiles) {
                    self.observationDataSource.limitingRegion = [ExploreRegion regionFromMKMapRect:mapView.visibleMapRect];
                }
            }
        }
    }
    
    // wait to set the delegate and receive regionDidChange notifications until
    // after the view has completely finished loading
    mapView.delegate = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    mapViewHasRenderedTiles = NO;
    
    mapView = ({
        // use autolayout
        MKMapView *map = [[MKMapView alloc] initWithFrame:CGRectZero];
        map.translatesAutoresizingMaskIntoConstraints = NO;
        
        map.mapType = MKMapTypeHybrid;
        
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

- (void)activeSearchPredicatesChanged {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.observationDataSource activeSearchLimitedBySearchedLocation]) {
            // remove any overlays that were already there
            [mapView removeOverlays:mapView.overlays];
            
            CLLocationCoordinate2D newCenter;
            MKMapRect newMapRect = MKMapRectNull;
            NSInteger overlayLocationId = 0;
            for (ExploreSearchPredicate *predicate in self.observationDataSource.activeSearchPredicates) {
                if (predicate.type == ExploreSearchPredicateTypeLocation) {
                    newCenter = predicate.searchLocation.location;
                    overlayLocationId = predicate.searchLocation.locationId;
                    newMapRect = predicate.searchLocation.boundingBox;
                    break;  // prefer places to projects
                } if (predicate.type == ExploreSearchPredicateTypeProject) {
                    if (predicate.searchProject.latitude != 0) {
                        newCenter = CLLocationCoordinate2DMake(predicate.searchProject.latitude,
                                                               predicate.searchProject.longitude);
                        overlayLocationId = predicate.searchProject.locationId;
                        break;
                    }
                }
            }
            
            if (!MKMapRectIsEmpty(newMapRect)) {
                [self addOverlaysForLocationId:overlayLocationId];
                MKCoordinateRegion region = MKCoordinateRegionForMapRect(newMapRect);
                [mapView setRegion:region animated:YES];
            } else if (overlayLocationId != 0) {
                [self addOverlaysForLocationId:overlayLocationId];
                if (CLLocationCoordinate2DIsValid(newCenter)) {
                    [mapView setCenterCoordinate:newCenter animated:YES];
                }
            }
            
        } else if (![self.observationDataSource activeSearchLimitedBySearchedLocation] && mapView.overlays.count > 0) {
            // if necessary, remove the overlays
            [mapView removeOverlays:mapView.overlays];
        }
    });
}

- (void)observationChangedCallback {
    dispatch_async(dispatch_get_main_queue(), ^{
        // in case this callback fires because of a change in search,
        // invalidate the map changed timer. unlikely but be safe.
        [mapChangedTimer invalidate];
        
        // try to be smart about updating the visible annotations
        // sweep through and remove any annotations that aren't in the visible map rect anymore
        [mapView removeAnnotations:[mapView.annotations bk_select:^BOOL(id <MKAnnotation> annotation) {
            return !MKMapRectContainsPoint(mapView.visibleMapRect, MKMapPointForCoordinate(annotation.coordinate));
        }]];
        
        // sweep through and remove any annotations that aren't in the active observations list anymore
        [mapView removeAnnotations:[mapView.annotations bk_select:^BOOL(id <MKAnnotation> annotation) {
            return ![self.observationDataSource.observations containsObject:annotation];
        }]];
        
        // compile candidates for adding to the map
        NSArray *sortedCandidates = [self.observationDataSource.mappableObservations bk_select:^BOOL(ExploreObservation *candidate) {
            return CLLocationCoordinate2DIsValid(candidate.coordinate) &&
            MKMapRectContainsPoint(mapView.visibleMapRect, MKMapPointForCoordinate(candidate.coordinate));
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
        
    });
}

#pragma mark - MKMapViewDelegate

- (void)mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered {
    //sentinal that the mapview has rendered at least once
    mapViewHasRenderedTiles = YES;
}

- (void)mapView:(MKMapView *)mv regionWillChangeAnimated:(BOOL)animated {
    [mapChangedTimer invalidate];
}

- (void)mapView:(MKMapView *)mv regionDidChangeAnimated:(BOOL)animated {
    if ([self.navigationController.topViewController isKindOfClass:[ExploreContainerViewController class]]) {
        ExploreContainerViewController *container = (ExploreContainerViewController *)self.navigationController.topViewController;
        if ([container.selectedViewController isEqual:self] && [self.tabBarController.selectedViewController isEqual:self.navigationController]) {
            [mapChangedTimer invalidate];
            
            __weak typeof(self) weakSelf = self;
            // give the user a bit to keep scrolling before we make a new API call
            mapChangedTimer = [NSTimer bk_scheduledTimerWithTimeInterval:0.75f
                                                                   block:^(NSTimer *timer) {
                                                                       __strong typeof(weakSelf) strongSelf = weakSelf;
                                                                       // notify the observation data source that we have a new limiting region
                                                                       ExploreRegion *region = [ExploreRegion regionFromMKMapRect:mv.visibleMapRect];
                                                                       strongSelf.observationDataSource.limitingRegion = region;
                                                                   }
                                                                 repeats:NO];
        }
    }
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
    FAKIcon *mapMarker = [FAKIonIcons iosLocationIconWithSize:25.0f];
    ExploreObservation *observation = (ExploreObservation *)annotation;
    [mapMarker addAttribute:NSForegroundColorAttributeName value:[UIColor colorForIconicTaxon:observation.iconicTaxonName]];
    FAKIcon *mapOutline = [FAKIonIcons iosLocationOutlineIconWithSize:25.0f];
    [mapOutline addAttribute:NSForegroundColorAttributeName value:[[UIColor colorForIconicTaxon:observation.iconicTaxonName] darkerColor]];
    
    // offset the marker so that the point of the pin (rather than the center of the glyph) is at the location of the observation
    [mapMarker addAttribute:NSBaselineOffsetAttributeName value:@(25.0f)];
    [mapOutline addAttribute:NSBaselineOffsetAttributeName value:@(25.0f)];
    annotationView.image = [UIImage imageWithStackedIcons:@[mapMarker, mapOutline] imageSize:CGSizeMake(25.0f, 50.0f)];
    
    
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

- (void)mapView:(MKMapView *)map didSelectAnnotationView:(MKAnnotationView *)view {
    // do nothing if the user taps their location annotation
    if ([view.annotation isKindOfClass:[MKUserLocation class]]) {
        return;
    }
    
    // deselect the annotation so the user can select it again
    [mapView deselectAnnotation:view.annotation animated:NO];
    
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    ObsDetailV2ViewController *obsDetail = [mainStoryboard instantiateViewControllerWithIdentifier:@"obsDetailV2"];
    ExploreObservation *selectedObservation = (ExploreObservation *)view.annotation;
    obsDetail.observation = selectedObservation;
    [self.navigationController pushViewController:obsDetail animated:YES];
    [[Analytics sharedClient] event:kAnalyticsEventNavigateObservationDetail
                     withProperties:@{ @"via": @"Explore Map" }];
}

#pragma mark - iNat API Calls

- (void)addOverlaysForLocationId:(NSInteger)locationId {
    // fetch the geometry file
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"/places/geometry/%ld.geojson", (long)locationId]
                        relativeToURL:[NSURL inat_baseURL]];
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

#pragma mark - Allow location search to update map location

- (void)mapShouldZoomToCoordinates:(CLLocationCoordinate2D)coords showUserLocation:(BOOL)showUserLocation {
    MKCoordinateRegion mapRegion;
    mapRegion.center = coords;
    
    // totally approximate, degree of latitude in a mile in meters
    CLLocationDegrees degreesRadius = 1609.0 / 111694.0;
    mapRegion.span.latitudeDelta = degreesRadius;
    mapRegion.span.longitudeDelta = degreesRadius;
    
    [mapView setRegion:mapRegion animated: YES];
    mapView.showsUserLocation = showUserLocation;
}

@end
