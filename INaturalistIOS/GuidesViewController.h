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

@interface GuidesViewController : UITableViewController <RKObjectLoaderDelegate, CLLocationManagerDelegate, GuideViewControllerDelegate>
@property (nonatomic, strong) NSArray *guides;
@property (nonatomic, strong) RKObjectLoader *loader;
@property (nonatomic, strong) NSDate *guideUsersSyncedAt;
//@property (nonatomic, strong) NSDate *featuredGuidesSyncedAt;
@property (nonatomic, strong) NSDate *allGuidesSyncedAt;
@property (nonatomic, strong) NSDate *nearbyGuidesSyncedAt;
@property (nonatomic, strong) UILabel *noContentLabel;
@property (nonatomic, strong) GuidesSearchController *guidesSearchController;
@property (nonatomic, strong) UISegmentedControl *listControl;
@property (nonatomic, strong) UIBarButtonItem *listControlItem;
@property (nonatomic, strong) UIBarButtonItem *syncActivityItem;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *lastLocation;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *syncButton;

- (IBAction)clickedSync:(id)sender;
- (void)loadData;
- (void)sync;
- (void)syncAllGuides;
- (void)syncNearbyGuides;
- (void)syncUserGuides;
- (void)stopSync;
- (void)checkEmpty;
@end
