//
//  LoginViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/17/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPPSignIn.h"
#import "INatWebController.h"
#import "LoginController.h"

@class LoginViewController;

@protocol LoginViewControllerDelegate <NSObject>
@optional
- (void)loginViewControllerDidLogIn:(LoginViewController *)controller;
- (void)loginViewControllerDidCancel:(LoginViewController *)controller;
- (void)loginViewControllerFailedToLogIn:(LoginViewController *)controller;
@end

@interface LoginViewController : UITableViewController <RKRequestDelegate, UIAlertViewDelegate, GPPSignInDelegate, INatWebControllerDelegate>

@property (nonatomic, weak) id <LoginViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;

- (IBAction)signIn:(id)sender;
- (IBAction)cancel:(id)sender;
- (void)failedLogin;
- (void)failedLogin:(NSString *)msg;
@end
