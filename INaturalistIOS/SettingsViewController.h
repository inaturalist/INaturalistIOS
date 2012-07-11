//
//  SettingsViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/27/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoginViewController.h"

@interface SettingsViewController : UITableViewController <LoginViewControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) NSString *versionText;
- (void)initUI;
- (void)clickedSignOut;
- (void)signOut;
- (void)localSignOut;
- (void)networkUnreachableAlert;
- (void)launchTutorial;
- (void)sendSupportEmail;
@end
