//
//  MapViewController.h
//  INaturalistIOS
//
//  Created by Scott Loarie on 2/22/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "MapTypeViewController.h"

@interface MapViewController : UIViewController <MKMapViewDelegate, MapTypeViewControllerDelegate>
@property (nonatomic, strong) NSMutableArray *observations;
@property (nonatomic, strong) UIBarButtonItem *currentLocationButton;
@property (nonatomic, strong) UIBarButtonItem *mapTypeButton;
- (void)clickedCurrentLocationButton;
- (void)clickedMapTypeButton;
@end
