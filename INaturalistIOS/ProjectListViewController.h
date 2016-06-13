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
@property (weak, nonatomic) IBOutlet UIImageView *projectIcon;
@property (weak, nonatomic) IBOutlet UILabel *projectTitle;
@property (weak, nonatomic) IBOutlet UIButton *detailsButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *syncButton;

- (IBAction)clickedSync:(id)sender;
@end
