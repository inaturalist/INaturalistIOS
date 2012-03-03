//
//  MapViewController.h
//  INaturalistIOS
//
//  Created by Scott Loarie on 2/22/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface MapViewController : UIViewController <MKMapViewDelegate>
@property (nonatomic, strong) NSMutableArray *observations;
@end
