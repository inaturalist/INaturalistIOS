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

@interface ProjectsViewController : UITableViewController <RKObjectLoaderDelegate, CLLocationManagerDelegate>
@property (nonatomic, strong) NSMutableArray *projects;
@property (nonatomic, strong) RKObjectLoader *loader;
@property (nonatomic, strong) NSDate *projectUsersSyncedAt;
@property (nonatomic, strong) NSDate *featuredProjectsSyncedAt;
@property (nonatomic, strong) NSDate *nearbyProjectsSyncedAt;
@property (nonatomic, strong) UILabel *noContentLabel;
@property (nonatomic, strong) ProjectsSearchController *projectsSearchController;
@property (nonatomic, strong) UISegmentedControl *listControl;
@property (nonatomic, strong) UIBarButtonItem *listControlItem;
@property (nonatomic, strong) UIBarButtonItem *syncActivityItem;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *lastLocation;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *syncButton;

- (IBAction)clickedSync:(id)sender;
- (void)loadData;
- (void)sync;
- (void)stopSync;
- (void)checkEmpty;
@end
