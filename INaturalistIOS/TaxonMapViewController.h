//
//  TaxonMapViewController.h
//  iNaturalist
//
//  Created by Alex Shepard on 5/23/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@import CoreLocation;
@import MapKit;
@class ExploreTaxonRealm;

@interface TaxonMapViewController : UIViewController
@property IBOutlet MKMapView *mapView;
@property ExploreTaxonRealm *etr;
@property CLLocationCoordinate2D observationCoordinate;
@property MKMapRect mapRect;
@end
