//
//  GuidesViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/1/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "GuidesSearchController.h"
#import "GuideViewController.h"

@interface GuidesViewController : UITableViewController <CLLocationManagerDelegate, GuideViewControllerDelegate>
@property (nonatomic, strong) UISegmentedControl *listControl;
@property (nonatomic, strong) UIBarButtonItem *listControlItem;
@property (nonatomic, strong) UIBarButtonItem *syncActivityItem;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *lastLocation;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *searchButton;

- (IBAction)tappedSearch:(id)sender;
@end
