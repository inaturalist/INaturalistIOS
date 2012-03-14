//
//  ProjectsViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/12/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoginViewController.h"

@interface ProjectsViewController : UITableViewController <RKObjectLoaderDelegate, LoginViewControllerDelegate>
@property (nonatomic, strong) NSMutableArray *projectUsers;
@property (nonatomic, strong) RKObjectLoader *loader;

- (IBAction)clickedSync:(id)sender;
- (void)loadData;
- (void)sync;
- (void)stopSync;
@end
