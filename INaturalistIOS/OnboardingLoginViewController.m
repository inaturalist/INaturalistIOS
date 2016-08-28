//
//  OnboardingLoginViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 8/4/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

@import CoreTelephony;

#import <UIColor-HTMLColors/UIColor+HTMLColors.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <NXOAuth2Client/NXOAuth2.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <objc/runtime.h>

#import "OnboardingLoginViewController.h"
#import "UIColor+INaturalist.h"
#import "LoginController.h"
#import "INaturalistAppDelegate.h"
#import "OnboardingPageViewController.h"
#import "UITapGestureRecognizer+InatHelpers.h"
#import "IconAndTextControl.h"
#import "Analytics.h"
#import "PartnerController.h"
#import "Partner.h"

static char PARTNER_ASSOCIATED_KEY;

@interface OnboardingLoginViewController () <UITextFieldDelegate> {
    UIAlertView *partnerAlert;
}
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
@property IBOutlet UIButton *closeButton;

@property IBOutlet IconAndTextControl *facebookButton;
@property IBOutlet IconAndTextControl *googleButton;

@property IBOutlet UILabel *termsLabel;
@property IBOutlet UILabel *licenseMyDataLabel;

@property BOOL licenseMyData;

@property NSArray <FAKIcon *> *leftViewIcons;

@property Partner *selectedPartner;

@end

@implementation OnboardingLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.leftViewIcons = @[
                                 ({
                                     FAKIcon *email = [FAKIonIcons iosEmailOutlineIconWithSize:30];
                                     [email addAttribute:NSForegroundColorAttributeName
                                                   value:[UIColor colorWithHexString:@"#4a4a4a"]];
                                      email;
                                 }),
                                 ({
                                     FAKIcon *lock = [FAKIonIcons iosLockedOutlineIconWithSize:30];
                                     [lock addAttribute:NSForegroundColorAttributeName
                                                  value:[UIColor colorWithHexString:@"#4a4a4a"]];
                                     lock;
                                 }),
                                 ({
                                     FAKIcon *person = [FAKIonIcons iosPersonOutlineIconWithSize:30];
                                     [person addAttribute:NSForegroundColorAttributeName
                                                    value:[UIColor colorWithHexString:@"#4a4a4a"]];
                                     person;
                                 }),
                                 ];
    NSArray *fields = @[ self.emailField, self.passwordField, self.usernameField ];
    [fields enumerateObjectsUsingBlock:^(UITextField *field, NSUInteger idx, BOOL * _Nonnull stop) {
        field.tag = idx;
        field.leftView = ({
            UILabel *label = [UILabel new];
            
            label.textAlignment = NSTextAlignmentCenter;
            label.frame = CGRectMake(0, 0, 60, 44);
            
            label.attributedText = [self.leftViewIcons[idx] attributedString];
            
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
    
    FAKIcon *closeIcon = [FAKIonIcons iosCloseEmptyIconWithSize:30];
    [closeIcon addAttribute:NSForegroundColorAttributeName
                      value:[UIColor colorWithHexString:@"#4a4a4a"]];
    [self.closeButton setAttributedTitle:closeIcon.attributedString
                                forState:UIControlStateNormal];
    
    self.closeButton.hidden = self.skippable;
    
    
    // terms label
    NSString *base = NSLocalizedString(@"By using iNaturalist you agree to the Terms of Service and Privacy Policy.", @"Base text for terms of service and privacy policy notice when creating an iNat account.");
    NSString *terms = NSLocalizedString(@"Terms of Service", @"Emphasized part of the terms of service base text.");
    NSString *privacy = NSLocalizedString(@"Privacy Policy", @"Emphasized part of the privacy base text.");
    
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:base
                                                                             attributes:@{
                                                                                          NSFontAttributeName: [UIFont systemFontOfSize:13]
                                                                                          }];
    NSRange termsRange = [base rangeOfString:terms];
    if (termsRange.location != NSNotFound) {
        [attr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:13] range:termsRange];
    }
    
    NSRange privacyRange = [base rangeOfString:privacy];
    if (privacyRange.location != NSNotFound) {
        [attr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:13] range:privacyRange];
    }
    
    self.termsLabel.attributedText = attr;
    
    UIGestureRecognizer *tap = [[UITapGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender,
                                                                                    UIGestureRecognizerState state,
                                                                                    CGPoint location) {
        
        UITapGestureRecognizer *tapSender = (UITapGestureRecognizer *)sender;
        if ([tapSender didTapAttributedTextInLabel:self.termsLabel inRange:termsRange]) {
            NSURL *termsURL = [NSURL URLWithString:@"http://www.inaturalist.org/pages/terms"];
            [[UIApplication sharedApplication] openURL:termsURL];
        } else if ([tapSender didTapAttributedTextInLabel:self.termsLabel inRange:privacyRange]) {
            NSURL *privacyURL = [NSURL URLWithString:@"http://www.inaturalist.org/pages/privacy"];
            [[UIApplication sharedApplication] openURL:privacyURL];
        }
    }];
    self.termsLabel.userInteractionEnabled = YES;
    [self.termsLabel addGestureRecognizer:tap];

    
    // license my content label
    
    base = NSLocalizedString(@"Yes, license my content so scientists can use my data. Learn More", @"Base text for the license my content checkbox during account creation");
    NSString *emphasis = NSLocalizedString(@"Learn More", @"Emphasis text for the license my content checkbox. Must be a substring of the base string.");
    
    attr = [[NSMutableAttributedString alloc] initWithString:base
                                                  attributes:@{
                                                               NSFontAttributeName: [UIFont systemFontOfSize:13]
                                                               }];
    NSRange emphasisRange = [base rangeOfString:emphasis];
    if (emphasisRange.location != NSNotFound) {
        [attr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:13] range:emphasisRange];
        
        UIGestureRecognizer *tap = [[UITapGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender,
                                                                                        UIGestureRecognizerState state,
                                                                                        CGPoint location) {
            
            NSString *alertTitle = NSLocalizedString(@"Content Licensing", @"Title for About Content Licensing notice during signup");
            NSString *creativeCommons = NSLocalizedString(@"Check this box if you want to apply a Creative Commons Attribution-NonCommercial license to your photos. You can choose a different license or remove the license later, but this is the best license for sharing with researchers.", @"Alert text for the license content checkbox during create account.");
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:alertTitle
                                                            message:creativeCommons
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            
        }];
        
        self.licenseMyDataLabel.userInteractionEnabled = YES;
        [self.licenseMyDataLabel addGestureRecognizer:tap];
    }
    self.licenseMyDataLabel.attributedText = attr;

    [@[self.facebookButton, self.googleButton] enumerateObjectsUsingBlock:^(IconAndTextControl *btn, NSUInteger idx, BOOL * _Nonnull stop) {
        btn.layer.cornerRadius = 2.0f;
        btn.backgroundColor = [UIColor colorWithHexString:@"#dddddd"];
        btn.separatorColor = [UIColor colorWithHexString:@"#cccccc"];
        btn.textColor = [UIColor colorWithHexString:@"#4a4a4a"];
    }];
    self.facebookButton.attributedIconTitle = ({
        FAKIcon *facebook = [FAKIonIcons socialFacebookIconWithSize:22];
        [facebook addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#666666"]];
        [facebook attributedString];
    });
    self.facebookButton.textTitle = @"Facebook";
    [self.facebookButton addTarget:self action:@selector(facebookPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    self.googleButton.attributedIconTitle = ({
        FAKIcon *google = [FAKIonIcons socialGoogleplusIconWithSize:22];
        [google addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#666666"]];
        [google attributedString];
    });
    self.googleButton.textTitle = @"Google";
    [self.googleButton addTarget:self action:@selector(googlePressed:) forControlEvents:UIControlEventTouchUpInside];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    PartnerController *partners = [[PartnerController alloc] init];    
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    if (info) {
        CTCarrier *carrier = info.subscriberCellularProvider;
        if (carrier) {
            Partner *p = [partners partnerForMobileCountryCode:carrier.mobileCountryCode];
            if (p) {
                [self showPartnerAlertForPartner:p];
            }
        }
    }
    
    if (self.startsInLoginMode && self.textfieldStackView.arrangedSubviews.count == 3) {
        [self switchAuthContext:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UITextFieldDelegate

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

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    UILabel *leftViewLabel = (UILabel *)[textField leftView];
    FAKIcon *icon = self.leftViewIcons[textField.tag];
    [icon addAttribute:NSForegroundColorAttributeName value:[UIColor inatTint]];
    [leftViewLabel setAttributedText:icon.attributedString];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    UILabel *leftViewLabel = (UILabel *)[textField leftView];
    FAKIcon *icon = self.leftViewIcons[textField.tag];
    [icon addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#4a4a4a"]];
    [leftViewLabel setAttributedText:icon.attributedString];
}

#pragma mark - UIControl targets

- (IBAction)actionPressed:(id)sender {
    if (self.textfieldStackView.arrangedSubviews.count == 2) {
        [self login];
    } else {
    	[self signup];
    }
}

- (IBAction)switchAuthContext:(id)sender {
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
    [[Analytics sharedClient] event:kAnalyticsEventSplashFacebook
                     withProperties:@{ @"Version": @"Onboarding" }];
    
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                    message:NSLocalizedString(@"Try again next time you're connected to the Internet.", nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK",nil)
                          otherButtonTitles:nil] show];
        return;
    }
    
    __weak typeof(self)weakSelf = self;
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.loginController loginWithFacebookViewController:self
                                                         success:^(NSDictionary *info) {
                                                             __strong typeof(weakSelf)strongSelf = weakSelf;
                                                             
                                                             if ([appDelegate.window.rootViewController isKindOfClass:[OnboardingPageViewController class]]) {
                                                                 [appDelegate showMainUI];
                                                             } else {
                                                                 [strongSelf dismissViewControllerAnimated:YES completion:nil];
                                                             }
                                                             if (strongSelf.selectedPartner) {
                                                                 [appDelegate.loginController loggedInUserSelectedPartner:strongSelf.selectedPartner
                                                                                                               completion:nil];
                                                             }

                                                         } failure:^(NSError *error) {
                                                             NSString *alertTitle = NSLocalizedString(@"Log In Problem", @"Title for login problem alert");
                                                             NSString *alertMsg;
                                                             if (error) {
                                                                 alertMsg = error.localizedDescription;
                                                             } else {
                                                                 alertMsg = NSLocalizedString(@"Failed to login to Facebook. Please try again later.",
                                                                                              @"Unknown facebook login error");
                                                             }
                                                             
                                                             [[[UIAlertView alloc] initWithTitle:alertTitle
                                                                                         message:alertMsg
                                                                                        delegate:nil
                                                                               cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                                               otherButtonTitles:nil] show];
                                                         }];
}

- (IBAction)googlePressed:(id)sender {
    [[Analytics sharedClient] event:kAnalyticsEventSplashGoogle
                     withProperties:@{ @"Version": @"Onboarding" }];
    
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                    message:NSLocalizedString(@"Try again next time you're connected to the Internet.", nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK",nil)
                          otherButtonTitles:nil] show];
        return;
    }
    
    __weak typeof(self)weakSelf = self;
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [appDelegate.loginController loginWithGoogleUsingViewController:self
                                                            success:^(NSDictionary *info) {
                                                               __strong typeof(weakSelf)strongSelf = weakSelf;
                                                               
                                                               if ([appDelegate.window.rootViewController isKindOfClass:[OnboardingPageViewController class]]) {
                                                                   [appDelegate showMainUI];
                                                               } else {
                                                                   [strongSelf dismissViewControllerAnimated:YES completion:nil];
                                                               }

                                                               if (strongSelf.selectedPartner) {
                                                                   [appDelegate.loginController loggedInUserSelectedPartner:strongSelf.selectedPartner
                                                                                                                 completion:nil];
                                                               }

                                                            } failure:^(NSError *error) {
                                                               NSString *alertTitle = NSLocalizedString(@"Log In Problem",
                                                                                                        @"Title for login problem alert");
                                                               NSString *alertMsg;
                                                               if (error) {
                                                                   alertMsg = error.localizedDescription;
                                                               } else {
                                                                   alertMsg = NSLocalizedString(@"Failed to login to Google Plus. Please try again later.",
                                                                                                @"Unknown google login error");
                                                               }
                                                               [[[UIAlertView alloc] initWithTitle:alertTitle
                                                                                           message:alertMsg
                                                                                          delegate:nil
                                                                                 cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                                                 otherButtonTitles:nil] show];
                                                           }];
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

- (IBAction)closePressed:(id)sender {
    if (self.closeAction) {
        self.closeAction();
    } else {
        [self dismissViewControllerAnimated:YES
                                 completion:nil];
    }
}

#pragma mark - Actions

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

                                                    if (strongSelf.selectedPartner) {
                                                        [appDelegate.loginController loggedInUserSelectedPartner:strongSelf.selectedPartner
                                                                                                      completion:nil];
                                                    }
                                                    
                                                    if ([appDelegate.window.rootViewController isKindOfClass:[OnboardingPageViewController class]]) {
                                                        [appDelegate showMainUI];
                                                    } else {
                                                        [strongSelf dismissViewControllerAnimated:YES completion:nil];
                                                    }
                                                }
     
     
                                                failure:^(NSError *error) {

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
                                               if (strongSelf.selectedPartner) {
                                                   [appDelegate.loginController loggedInUserSelectedPartner:strongSelf.selectedPartner
                                                                                                 completion:nil];
                                               }
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

#pragma mark - Partner alert helper

- (void)showPartnerAlertForPartner:(Partner *)partner {
    if (!partner) { return; }
    
    [[Analytics sharedClient] event:kAnalyticsEventPartnerAlertPresented
                     withProperties:@{ @"Partner": partner.name }];
    
    NSString *alertTitle = [NSString stringWithFormat:NSLocalizedString(@"Use %@?",
                                                                        @"join iNat network partner alert title"),
                            partner.name];
    NSString *alertMsgFmt = NSLocalizedString(@"Would you like to use %@, a member of the iNaturalist Network in %@? Clicking OK will localize your experience and share data accordingly.",
                                              @"join iNat network partner alert message");
    NSString *alertMsg = [NSString stringWithFormat:alertMsgFmt, partner.name, partner.countryName];
    
    partnerAlert = [[UIAlertView alloc] initWithTitle:alertTitle
                                              message:alertMsg
                                             delegate:self
                                    cancelButtonTitle:NSLocalizedString(@"No", nil)
                                    otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    
    if (partner.logo) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 45)];
        
        UIImageView *iv = [[UIImageView alloc] initWithImage:partner.logo];
        iv.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        iv.center = CGPointMake(view.center.x, view.center.y - 5);
        iv.contentMode = UIViewContentModeScaleAspectFit;
        
        [view addSubview:iv];
        [partnerAlert setValue:view forKey:@"accessoryView"];
    }
    objc_setAssociatedObject(partnerAlert, &PARTNER_ASSOCIATED_KEY, partner, OBJC_ASSOCIATION_RETAIN);
    [partnerAlert show];
}

#pragma mark AlertView delegate

- (void)alertView:(nonnull UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == partnerAlert) {
        
        [[Analytics sharedClient] event:kAnalyticsEventPartnerAlertResponse
                         withProperties:@{ @"Response": (buttonIndex == 1) ? @"Yes" : @"No" }];
        
        if (buttonIndex == 1) {
            Partner *p = objc_getAssociatedObject(alertView, &PARTNER_ASSOCIATED_KEY);
            // be extremely defensive here. an invalid baseURL shouldn't be possible,
            // but if it does happen, nothing in the app will work.
            NSURL *partnerURL = [p baseURL];
            if (partnerURL) {
                [[NSUserDefaults standardUserDefaults] setObject:partnerURL.absoluteString
                                                          forKey:kInatCustomBaseURLStringKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [((INaturalistAppDelegate *)[UIApplication sharedApplication].delegate) reconfigureForNewBaseUrl];
                self.selectedPartner = p;
            }
        } else {
            // revert to default base URL
            [[NSUserDefaults standardUserDefaults] setObject:nil
                                                      forKey:kInatCustomBaseURLStringKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [((INaturalistAppDelegate *)[UIApplication sharedApplication].delegate) reconfigureForNewBaseUrl];
        }
    }
}


@end
