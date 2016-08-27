//
//  OnboardingLoginViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 8/4/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <UIColor-HTMLColors/UIColor+HTMLColors.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <NXOAuth2Client/NXOAuth2.h>

#import "OnboardingLoginViewController.h"
#import "UIColor+INaturalist.h"
#import "LoginController.h"
#import "INaturalistAppDelegate.h"
#import "OnboardingPageViewController.h"

@interface OnboardingLoginViewController () <UITextFieldDelegate>
@property IBOutlet UILabel *titleLabel;

@property IBOutlet UIStackView *textfieldStackView;
@property IBOutlet UITextField *usernameField;
@property IBOutlet UITextField *passwordField;
@property IBOutlet UITextField *emailField;

@property IBOutlet UIStackView *licenseStackView;
@property IBOutlet UIButton *licenseMyDataButton;

@property IBOutlet UIButton *actionButton;
@property IBOutlet UIButton *switchContextButton;

@property IBOutlet UIButton *skipButton;

@property BOOL licenseMyData;

@end

@implementation OnboardingLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray *leftViewIcons = @[
                               ({
                                   FAKIcon *email = [FAKIonIcons iosEmailOutlineIconWithSize:30];
                                   [email addAttribute:NSForegroundColorAttributeName
                                                 value:[UIColor colorWithHexString:@"#4a4a4a"]];
                                   email.attributedString;
                               }),
                               ({
                                   FAKIcon *lock = [FAKIonIcons iosLockedOutlineIconWithSize:30];
                                   [lock addAttribute:NSForegroundColorAttributeName
                                                value:[UIColor colorWithHexString:@"#4a4a4a"]];
                                   lock.attributedString;
                               }),
                               ({
                                   FAKIcon *person = [FAKIonIcons iosPersonOutlineIconWithSize:30];
                                   [person addAttribute:NSForegroundColorAttributeName
                                                  value:[UIColor colorWithHexString:@"#4a4a4a"]];
                                   person.attributedString;
                               }),
                               ];
    NSArray *fields = @[ self.emailField, self.passwordField, self.usernameField ];
    [fields enumerateObjectsUsingBlock:^(UITextField *field, NSUInteger idx, BOOL * _Nonnull stop) {
        field.leftView = ({
            UILabel *label = [UILabel new];
            
            label.textAlignment = NSTextAlignmentCenter;
            label.frame = CGRectMake(0, 0, 60, 44);
            
            label.attributedText = leftViewIcons[idx];
            
            label;
        });
        field.leftViewMode = UITextFieldViewModeAlways;
    }];
    
    FAKIcon *check = [FAKIonIcons iosCheckmarkOutlineIconWithSize:30];
    [self.licenseMyDataButton setAttributedTitle:check.attributedString
                                        forState:UIControlStateNormal];
    self.licenseMyData = YES;
    
    self.actionButton.backgroundColor = [UIColor inatTint];
    
    self.skipButton.layer.borderColor = [UIColor colorWithHexString:@"#4a4a4a"].CGColor;
    self.skipButton.layer.cornerRadius = 20.0f;
    self.skipButton.layer.borderWidth = 1.0f;
    
    self.skipButton.contentEdgeInsets = UIEdgeInsetsMake(-5, 15, -5, 15);
    if ([self.skipButton respondsToSelector:@selector(setLayoutMargins:)]) {
        self.skipButton.layoutMargins = UIEdgeInsetsMake(50, 0, 50, 0);
    }
    self.skipButton.hidden = !self.skippable;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.emailField) {
        [self.usernameField becomeFirstResponder];
    } else if (textField == self.usernameField) {
        [self.passwordField becomeFirstResponder];
    } else if (textField == self.passwordField) {
        [self actionPressed:textField];
    }
    return YES;
}

- (IBAction)actionPressed:(id)sender {
    if (self.textfieldStackView.arrangedSubviews.count == 2) {
        [self login];
    } else {
    	[self signup];
    }
}

- (IBAction)switchAuthContext:(id)sender {
    NSLog(@"switch auth context");
    
    if (self.textfieldStackView.arrangedSubviews.count == 3) {
        // switch to login mode
        [UIView animateWithDuration:0.2f
                         animations:^{
                             [self.textfieldStackView removeArrangedSubview:self.emailField];
                             self.emailField.hidden = YES;
                             self.titleLabel.text = NSLocalizedString(@"Log In", nil);
                             [self.actionButton setTitle:NSLocalizedString(@"Log In", nil)
                                                forState:UIControlStateNormal];
                             self.licenseStackView.hidden = YES;
                             [self.switchContextButton setTitle:NSLocalizedString(@"New to iNaturalist? Sign up now!", nil)
                                                       forState:UIControlStateNormal];
                         }];
    } else {
        // switch to signup mode
        [UIView animateWithDuration:0.2f
                         animations:^{
                             [self.textfieldStackView insertArrangedSubview:self.emailField
                                                                    atIndex:0];
                             self.emailField.hidden = NO;
                             self.titleLabel.text = NSLocalizedString(@"Sign Up", nil);
                             [self.actionButton setTitle:NSLocalizedString(@"Sign Up", nil)
                                                forState:UIControlStateNormal];
                             self.licenseStackView.hidden = NO;
                             [self.switchContextButton setTitle:NSLocalizedString(@"Already have an account?", nil)
                                                       forState:UIControlStateNormal];
                         }];
    }
}


- (IBAction)facebookPressed:(id)sender {
    
}

- (IBAction)googlePressed:(id)sender {
    
}


- (IBAction)licenseTogglePressed:(id)sender {
    self.licenseMyData = !self.licenseMyData;
    if (self.licenseMyData) {
        FAKIcon *check = [FAKIonIcons iosCheckmarkOutlineIconWithSize:30];
        [self.licenseMyDataButton setAttributedTitle:check.attributedString
                                            forState:UIControlStateNormal];
    } else {
        FAKIcon *circle = [FAKIonIcons iosCircleOutlineIconWithSize:30];
        [self.licenseMyDataButton setAttributedTitle:circle.attributedString
                                            forState:UIControlStateNormal];
    }
}

- (IBAction)skipPressed:(id)sender {
    if (self.skipAction) {
        self.skipAction();
    }
}

- (void)signup {
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                    message:NSLocalizedString(@"Try again next time you're connected to the Internet.", nil)
                                   delegate:self
                          cancelButtonTitle:NSLocalizedString(@"OK",nil)
                          otherButtonTitles:nil] show];
        return;
    }
    
    // validators
    BOOL isValid = YES;
    NSString *alertMsg;
    if (!self.emailField.text || [self.emailField.text rangeOfString:@"@"].location == NSNotFound) {
        isValid = NO;
        alertMsg = NSLocalizedString(@"Invalid Email Address", "Error for bad email when making account.");
    }  else if (!self.passwordField.text || self.passwordField.text.length < INatMinPasswordLength) {
        isValid = NO;
        alertMsg = NSLocalizedString(@"Passwords must be six characters in length.",
                                     @"Error for bad password when making account");
    } else if (!self.usernameField.text) {
        isValid = NO;
        alertMsg = NSLocalizedString(@"Invalid Username", @"Error for bad username hwne making account.");
    }
    
    if (!isValid) {
        NSString *alertTitle = NSLocalizedString(@"Oops", @"Title error with oops text.");
        if (!alertMsg) alertMsg = NSLocalizedString(@"Invalid input", @"Unknown invalid input");
        
        [[[UIAlertView alloc] initWithTitle:alertTitle
                                    message:alertMsg
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
        return;
    }
    
    NSString *license = self.licenseMyData ? @"CC-BY_NC" : @"on";
    // TODO: partners
	NSInteger selectedPartnerId = 1;    
    
    UIView *hudView = self.parentViewController ? self.parentViewController.view : self.view;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:hudView animated:YES];
    hud.labelText = NSLocalizedString(@"Creating iNaturalist account...",
                                      @"Notice while we're creating an iNat account for them");
    hud.removeFromSuperViewOnHide = YES;
    hud.dimBackground = YES;

    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
    __weak typeof(self)weakSelf = self;
    [appDelegate.loginController createAccountWithEmail:self.emailField.text
                                               password:self.passwordField.text
                                               username:self.usernameField.text
                                                   site:selectedPartnerId
                                                license:license
                                                success:^(NSDictionary *info) {
                                                    __strong typeof(weakSelf)strongSelf = weakSelf;
                                                    
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        [MBProgressHUD hideAllHUDsForView:hudView animated:YES];
                                                    });

                                               if ([appDelegate.window.rootViewController isKindOfClass:[OnboardingPageViewController class]]) {
                                                        [appDelegate showMainUI];
                                                    } else {
                                                        [strongSelf dismissViewControllerAnimated:YES completion:nil];
                                                    }
                                                }
                                                failure:^(NSError *error) {
                                                    __strong typeof(weakSelf)strongSelf = weakSelf;

                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        [MBProgressHUD hideAllHUDsForView:hudView animated:YES];
                                                    });

                                                    NSString *alertTitle = NSLocalizedString(@"Oops", @"Title error with oops text.");
                                                    NSString *alertMsg;
                                                    if (error) {
                                                        alertMsg = error.localizedDescription;
                                                    } else {
                                                        alertMsg = NSLocalizedString(@"Failed to create an iNaturalist account. Please try again.",
                                                                                   @"Unknown iNaturalist create account error");
                                                    }
                                                    
                                                    [[[UIAlertView alloc] initWithTitle:alertTitle
                                                                                message:alertMsg
                                                                               delegate:nil
                                                                      cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                                      otherButtonTitles:nil] show];
                                                }];
}


- (void)login {
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                    message:NSLocalizedString(@"Try again next time you're connected to the Internet.", nil)
                                   delegate:self
                          cancelButtonTitle:NSLocalizedString(@"OK",nil)
                          otherButtonTitles:nil] show];
        return;
    }
    
    // validators
    BOOL isValid = YES;
    NSString *alertMsg;
    if (!self.usernameField.text) {
        isValid = NO;
        alertMsg = NSLocalizedString(@"Invalid Username",
                                     @"Error for bad username hwne making account.");
    }
    if (!self.passwordField.text || self.passwordField.text.length < INatMinPasswordLength) {
        isValid = NO;
        alertMsg = NSLocalizedString(@"Passwords must be six characters in length.",
                                     @"Error for bad password when making account");
    }
    if (!isValid) {
        NSString *alertTitle = NSLocalizedString(@"Oops", @"Title error with oops text.");
        if (!alertMsg) alertMsg = NSLocalizedString(@"Invalid input", @"Unknown invalid input");
        
        [[[UIAlertView alloc] initWithTitle:alertTitle
                                    message:alertMsg
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
        return;
    }
    
    UIView *hudView = self.parentViewController ? self.parentViewController.view : self.view;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:hudView animated:YES];
    hud.labelText = NSLocalizedString(@"Logging in...", @"Notice while we're logging them in");
    hud.removeFromSuperViewOnHide = YES;
    hud.dimBackground = YES;
    
    __weak typeof(self)weakSelf = self;
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate.loginController loginWithUsername:self.usernameField.text
                                          password:self.passwordField.text
                                           success:^(NSDictionary *info) {
                                               __strong typeof(weakSelf)strongSelf = weakSelf;
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   [MBProgressHUD hideAllHUDsForView:hudView animated:YES];
                                               });
                                               if ([appDelegate.window.rootViewController isKindOfClass:[OnboardingPageViewController class]]) {
                                                   [appDelegate showMainUI];
                                               } else {
                                                   [strongSelf dismissViewControllerAnimated:YES completion:nil];
                                               }
                                           } failure:^(NSError *error) {
                                               __strong typeof(weakSelf)strongSelf = weakSelf;
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   [MBProgressHUD hideAllHUDsForView:hudView animated:YES];
                                               });
                                               
                                               NSString *alertTitle = NSLocalizedString(@"Oops", @"Title error with oops text.");
                                               NSString *alertMsg;
                                               if (error) {
                                                   if ([error.domain isEqualToString:NXOAuth2HTTPErrorDomain] && error.code == 401) {
                                                       alertMsg = NSLocalizedString(@"Incorrect username or password.",
                                                                                    @"Error msg when we get a 401 from the server");
                                                   } else {
                                                       alertMsg = error.localizedDescription;
                                                   }
                                               } else {
                                                   alertMsg = NSLocalizedString(@"Failed to login to iNaturalist. Please try again.",
                                                                                @"Unknown iNat login error");
                                               }
                                               [[[UIAlertView alloc] initWithTitle:alertTitle
                                                                           message:alertMsg
                                                                          delegate:nil
                                                                 cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                                 otherButtonTitles:nil] show];
                                           }];

}

@end
