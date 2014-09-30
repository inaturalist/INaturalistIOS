//
//  MapViewController.h
//  iNaturalist
//
//  Created by Scott Loarie on 2/22/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "MapTypeViewController.h"
#import "ObservationDetailViewController.h"

@interface MapViewController : UIViewController <MKMapViewDelegate, MapTypeViewControllerDelegate, ObservationDetailViewControllerDelegate>
@property (nonatomic, strong) UIBarButtonItem *currentLocationButton;
@property (nonatomic, strong) UIBarButtonItem *mapTypeButton;
@property (nonatomic, strong) UIBarButtonItem *addObservationButton;
@property (nonatomic, strong) CLLocationManager *locationManager;
- (void)clickedCurrentLocationButton;
- (void)clickedMapTypeButton;
- (void)clickedAddObservationButton;
- (void)loadObservations;
@end
