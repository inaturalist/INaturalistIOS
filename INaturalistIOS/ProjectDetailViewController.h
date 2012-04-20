//
//  ProjectDetailViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/27/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Three20/Three20.h>
#import "Project.h"
#import "ProjectUser.h"
#import "LoginViewController.h"

@interface ProjectDetailViewController : UITableViewController <RKObjectLoaderDelegate, LoginViewControllerDelegate, UIAlertViewDelegate>
@property (nonatomic, strong) Project *project;
@property (nonatomic, strong) ProjectUser *projectUser;
@property (nonatomic, strong) NSMutableDictionary *sectionHeaderViews;
@property (weak, nonatomic) IBOutlet TTImageView *projectIcon;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *joinButton;
@property (weak, nonatomic) IBOutlet UILabel *projectTitle;
- (IBAction)clickedViewButton:(id)sender;
- (IBAction)clickedJoin:(id)sender;
- (void)join;
- (void)leave;
- (void)setupJoinButton;
@end
