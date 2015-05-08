//
//  ProjectDetailViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/14/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ObservationDetailViewController.h"

@class Project;
@class ProjectUser;

@interface ProjectListViewController : UITableViewController <RKObjectLoaderDelegate, ObservationDetailViewControllerDelegate>

@property (nonatomic, strong) Project *project;
@property (nonatomic, strong) ProjectUser *projectUser;
@property (nonatomic, assign) BOOL detailsPresented;
@property (nonatomic, strong) NSMutableArray *listedTaxa;
@property (weak, nonatomic) IBOutlet UIImageView *projectIcon;
@property (weak, nonatomic) IBOutlet UILabel *projectTitle;
@property (nonatomic, strong) RKObjectLoader *loader;
@property (nonatomic, strong) NSDate *lastSyncedAt;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *syncButton;
@property (strong, nonatomic) UIBarButtonItem *stopSyncButton;

- (IBAction)clickedSync:(id)sender;
- (void)clickedAdd:(id)sender event:(UIEvent *)event;
- (void)sync;
- (void)stopSync;
- (void)loadData;
@end
