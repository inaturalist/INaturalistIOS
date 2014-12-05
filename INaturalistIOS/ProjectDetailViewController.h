//
//  ProjectDetailViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/27/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Project.h"
#import "ProjectUser.h"
#import "LoginViewController.h"

@interface ProjectDetailViewController : UITableViewController <RKObjectLoaderDelegate, LoginViewControllerDelegate, UIAlertViewDelegate>
@property (nonatomic, strong) Project *project;
@property (nonatomic, strong) ProjectUser *projectUser;
@property (nonatomic, strong) NSMutableDictionary *sectionHeaderViews;
@property (weak, nonatomic) IBOutlet UIImageView *projectIcon;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *joinButton;
@property (weak, nonatomic) IBOutlet UILabel *projectTitle;
- (IBAction)clickedViewButton:(id)sender;
- (IBAction)clickedJoin:(id)sender;
- (IBAction)clickedClose:(id)sender;
- (void)join;
- (void)leave;
- (void)setupJoinButton;
- (NSInteger)heightForHTML:(NSString *)html;
@end
