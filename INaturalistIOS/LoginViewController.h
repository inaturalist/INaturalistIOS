//
//  LoginViewController.h
//  INaturalistIOS
//
//  Created by Ken-ichi Ueda on 2/17/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LoginViewController;

@protocol LoginViewControllerDelegate <NSObject>
- (void)loginViewControllerDidLogIn:(LoginViewController *)controller;
- (void)loginViewControllerFailedToLogIn:(LoginViewController *)controller;
@end

@interface LoginViewController : UITableViewController <RKRequestDelegate>

@property (nonatomic, weak) id <LoginViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;

- (IBAction)signIn:(id)sender;
- (IBAction)cancel:(id)sender;

@end
