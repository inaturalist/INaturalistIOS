//
//  TaxonMapViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/23/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonIcons.h>

#import "TaxonMapViewController.h"
#import "ExploreTaxonRealm.h"
#import "UIColor+ExploreColors.h"

@interface TaxonMapViewController () <MKMapViewDelegate>

@end

@implementation TaxonMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString *template = [NSString stringWithFormat:@"https://api.inaturalist.org/v1/colored_heatmap/{z}/{x}/{y}.png?taxon_id=%ld",
                          (long)[self.etr taxonId]];
    MKTileOverlay *overlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
    overlay.tileSize = CGSizeMake(512, 512);
    overlay.canReplaceMapContent = NO;
    [self.mapView addOverlay:overlay
                       level:MKOverlayLevelAboveLabels];
    
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!MKMapRectIsEmpty(self.mapRect)) {
        if (CLLocationCoordinate2DIsValid(self.observationCoordinate)) {
            // try to show both the map tiles of other observations _and_
            // the point for the current observation
            MKMapPoint obsPoint = MKMapPointForCoordinate(self.observationCoordinate);
            MKMapRect obsCoordRect = MKMapRectMake(obsPoint.x,
                                                   obsPoint.y,
                                                   0.1,
                                                   0.1);
            self.mapRect = MKMapRectUnion(self.mapRect, obsCoordRect);
        }
        [self.mapView setVisibleMapRect:self.mapRect
                            edgePadding:UIEdgeInsetsMake(20, 20, 20, 20)
                               animated:NO];
    }

    
    if (CLLocationCoordinate2DIsValid(self.observationCoordinate)) {
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
        annotation.coordinate = self.observationCoordinate;
        annotation.title = NSLocalizedString(@"Selected Observation", nil);
        [self.mapView addAnnotation:annotation];
        if (!MKMapRectContainsPoint([self.mapView visibleMapRect], MKMapPointForCoordinate(self.observationCoordinate))) {
            [self.mapView setCenterCoordinate:self.observationCoordinate];
        }
    }
}

#pragma - MKMapViewDelegate

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay {
    return [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
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
    [mapMarker addAttribute:NSForegroundColorAttributeName value:[UIColor colorForIconicTaxon:self.etr.iconicTaxonName]];
    FAKIcon *mapOutline = [FAKIonIcons iosLocationOutlineIconWithSize:25.0f];
    [mapOutline addAttribute:NSForegroundColorAttributeName value:[[UIColor colorForIconicTaxon:self.etr.iconicTaxonName] darkerColor]];
    
    // offset the marker so that the point of the pin (rather than the center of the glyph) is at the location of the observation
    [mapMarker addAttribute:NSBaselineOffsetAttributeName value:@(25.0f)];
    [mapOutline addAttribute:NSBaselineOffsetAttributeName value:@(25.0f)];
    annotationView.image = [UIImage imageWithStackedIcons:@[mapMarker, mapOutline] imageSize:CGSizeMake(25.0f, 50.0f)];
    
    return annotationView;
}


@end
