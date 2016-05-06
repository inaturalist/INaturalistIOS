//
//  ProjectsViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/12/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "ProjectsSearchController.h"

@interface ProjectsViewController : UITableViewController <CLLocationManagerDelegate>
@property (nonatomic, strong) NSArray *projects;
@property (nonatomic, strong) NSDate *projectUsersSyncedAt;
@property (nonatomic, strong) NSDate *featuredProjectsSyncedAt;
@property (nonatomic, strong) NSDate *nearbyProjectsSyncedAt;
@property (nonatomic, strong) UILabel *noContentLabel;
@property (nonatomic, strong) ProjectsSearchController *projectsSearchController;
@property (nonatomic, strong) UISegmentedControl *listControl;
@property (nonatomic, strong) UIBarButtonItem *syncActivityItem;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *lastLocation;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *searchButton;

- (IBAction)tappedSearch:(id)sender;
@end
