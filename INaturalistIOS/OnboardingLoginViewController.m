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
#import <RestKit/RestKit.h>

#import "OnboardingLoginViewController.h"
#import "UIColor+INaturalist.h"
#import "LoginController.h"
#import "INaturalistAppDelegate.h"
#import "OnboardingViewController.h"
#import "UITapGestureRecognizer+InatHelpers.h"
#import "IconAndTextControl.h"
#import "Analytics.h"
#import "PartnerController.h"
#import "Partner.h"
#import "INatWebController.h"
#import "INatReachability.h"

static char PARTNER_ASSOCIATED_KEY;

@interface OnboardingLoginViewController () <UITextFieldDelegate, INatWebControllerDelegate>

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

@property IBOutlet UILabel *orLabel;
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
    
    // design can't be made to accomodate iPhone 4s
    if ([UIScreen mainScreen].bounds.size.height < 568) {
        self.orLabel.hidden = YES;
        self.actionButton.hidden = YES;
    }
    
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
    
    self.skipButton.layer.borderColor = [UIColor colorWithHexString:@"#c0c0c0"].CGColor;
    self.skipButton.layer.cornerRadius = 20.0f;
    self.skipButton.layer.borderWidth = 1.0f;
    
    self.skipButton.contentEdgeInsets = UIEdgeInsetsMake(-5, 15, -5, 15);
    if ([self.skipButton respondsToSelector:@selector(setLayoutMargins:)]) {
        self.skipButton.layoutMargins = UIEdgeInsetsMake(50, 0, 50, 0);
    }
    self.skipButton.hidden = !self.skippable;
    [self.skipButton setTitle:NSLocalizedString(@"Skip ›", @"skip button title")
                     forState:UIControlStateNormal];
    
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
            NSURL *termsURL = [NSURL URLWithString:@"https://www.inaturalist.org/pages/terms"];
            [[UIApplication sharedApplication] openURL:termsURL];
        } else if ([tapSender didTapAttributedTextInLabel:self.termsLabel inRange:privacyRange]) {
            NSURL *privacyURL = [NSURL URLWithString:@"https://www.inaturalist.org/pages/privacy"];
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
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                           message:creativeCommons
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];            
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
    
    
    self.switchContextButton.backgroundColor = [UIColor colorWithHexString:@"#dddddd"];
    self.switchContextButton.tintColor = [UIColor colorWithHexString:@"#4a4a4a"];
    [self.switchContextButton setTitle:NSLocalizedString(@"Already have an account?", nil)
                              forState:UIControlStateNormal];

    self.passwordField.rightView = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectMake(0, 0, 65, 44);
        
        button.titleLabel.font = [UIFont systemFontOfSize:12.0f];
        button.tintColor = [UIColor colorWithHexString:@"#c0c0c0"];
        
        [button setTitle:NSLocalizedString(@"Forgot?", @"Title for forgot password button.")
                forState:UIControlStateNormal];
        
        __weak typeof(self)weakSelf = self;
        [button bk_addEventHandler:^(id sender) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (![[INatReachability sharedClient] isNetworkReachable]) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                                                               message:NSLocalizedString(@"Try again next time you're connected to the Internet.", nil)
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
                return;
            }
            
            INatWebController *webController = [[INatWebController alloc] init];
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/forgot_password.mobile", INatWebBaseURL]];
            [webController setUrl:url];
            webController.delegate = strongSelf;
            UIBarButtonItem *cancel = [[UIBarButtonItem alloc] bk_initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                      handler:^(id sender) {
                                                                                          __strong typeof(weakSelf)strongSelf = weakSelf;
                                                                                          [strongSelf dismissViewControllerAnimated:YES
                                                                                                                         completion:nil];
                                                                                      }];
            webController.navigationItem.leftBarButtonItem = cancel;
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:webController];
            [strongSelf presentViewController:nav animated:YES completion:nil];
            
        } forControlEvents:UIControlEventTouchUpInside];
        
        button;
    });
    
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
                             self.passwordField.rightViewMode = UITextFieldViewModeUnlessEditing;
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
                             self.passwordField.rightViewMode = UITextFieldViewModeNever;
                         }];
    }
}


- (IBAction)facebookPressed:(id)sender {
    if (![[INatReachability sharedClient] isNetworkReachable]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                                                       message:NSLocalizedString(@"Try again next time you're connected to the Internet.", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    [[Analytics sharedClient] event:kAnalyticsEventOnboardingLoginPressed
                     withProperties:@{ @"mode": @"facebook" }];
    
    __weak typeof(self)weakSelf = self;
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.loginController loginWithFacebookViewController:self
                                                         success:^(NSDictionary *info) {
                                                             __strong typeof(weakSelf)strongSelf = weakSelf;
                                                             
                                                             if ([appDelegate.window.rootViewController isKindOfClass:[OnboardingViewController class]]) {
                                                                 [appDelegate showMainUI];
                                                             } else {
                                                                 [strongSelf dismissViewControllerAnimated:YES completion:nil];
                                                             }
                                                             if (strongSelf.selectedPartner) {
                                                                 [appDelegate.loginController loggedInUserSelectedPartner:strongSelf.selectedPartner
                                                                                                               completion:nil];
                                                             }
                                                             [[NSNotificationCenter defaultCenter] postNotificationName:kINatLoggedInNotificationKey
                                                                                                                 object:nil];
                                                             
                                                         } failure:^(NSError *error) {
                                                             NSString *alertTitle = NSLocalizedString(@"Log In Problem", @"Title for login problem alert");
                                                             NSString *alertMsg;
                                                             if (error) {
                                                                 alertMsg = error.localizedDescription;
                                                             } else {
                                                                 alertMsg = NSLocalizedString(@"Failed to login to Facebook. Please try again later.",
                                                                                              @"Unknown facebook login error");
                                                             }
                                                             
                                                             UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                                                                            message:alertMsg
                                                                                                                     preferredStyle:UIAlertControllerStyleAlert];
                                                             [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                                                                       style:UIAlertActionStyleCancel
                                                                                                     handler:nil]];
                                                             [weakSelf presentViewController:alert animated:YES completion:nil];
                                                         }];
}

- (IBAction)googlePressed:(id)sender {
    if (![[INatReachability sharedClient] isNetworkReachable]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                                                       message:NSLocalizedString(@"Try again next time you're connected to the Internet.", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    [[Analytics sharedClient] event:kAnalyticsEventOnboardingLoginPressed
                     withProperties:@{ @"mode": @"google" }];
    
    __weak typeof(self)weakSelf = self;
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [appDelegate.loginController loginWithGoogleUsingViewController:self
                                                            success:^(NSDictionary *info) {
                                                                __strong typeof(weakSelf)strongSelf = weakSelf;
                                                                
                                                                if ([appDelegate.window.rootViewController isKindOfClass:[OnboardingViewController class]]) {
                                                                    [appDelegate showMainUI];
                                                                } else {
                                                                    [strongSelf dismissViewControllerAnimated:YES completion:nil];
                                                                }
                                                                
                                                                if (strongSelf.selectedPartner) {
                                                                    [appDelegate.loginController loggedInUserSelectedPartner:strongSelf.selectedPartner
                                                                                                                  completion:nil];
                                                                }
                                                                [[NSNotificationCenter defaultCenter] postNotificationName:kINatLoggedInNotificationKey
                                                                                                                    object:nil];
                                                                
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
                                                                UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                                                                               message:alertMsg
                                                                                                                        preferredStyle:UIAlertControllerStyleAlert];
                                                                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                                                                          style:UIAlertActionStyleCancel
                                                                                                        handler:nil]];
                                                                [weakSelf presentViewController:alert animated:YES completion:nil];
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
        [[Analytics sharedClient] event:kAnalyticsEventOnboardingLoginSkip];
        self.skipAction();
    }
}

- (IBAction)closePressed:(id)sender {
    [[Analytics sharedClient] event:kAnalyticsEventOnboardingLoginCancel];
    
    if (self.closeAction) {
        self.closeAction();
    } else {
        [self dismissViewControllerAnimated:YES
                                 completion:nil];
    }
}

#pragma mark - Actions

- (void)signup {
    if (![[INatReachability sharedClient] isNetworkReachable]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                                                       message:NSLocalizedString(@"Try again next time you're connected to the Internet.", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
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
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                       message:alertMsg
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    [[Analytics sharedClient] event:kAnalyticsEventOnboardingLoginPressed
                     withProperties:@{ @"mode": @"signup" }];
    
    NSString *license = self.licenseMyData ? @"CC-BY_NC" : @"on";
    NSInteger selectedPartnerId = self.selectedPartner ? self.selectedPartner.identifier : 1;
    
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
                                                        if (strongSelf.selectedPartner) {
                                                            [appDelegate.loginController loggedInUserSelectedPartner:strongSelf.selectedPartner
                                                                                                          completion:nil];
                                                        }
                                                        
                                                        if ([appDelegate.window.rootViewController isKindOfClass:[OnboardingViewController class]]) {
                                                            [appDelegate showMainUI];
                                                        } else {
                                                            [strongSelf dismissViewControllerAnimated:YES completion:nil];
                                                        }
                                                        [[NSNotificationCenter defaultCenter] postNotificationName:kINatLoggedInNotificationKey
                                                                                                            object:nil];
                                                    });
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
                                                    
                                                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                                                                   message:alertMsg
                                                                                                            preferredStyle:UIAlertControllerStyleAlert];
                                                    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                                                              style:UIAlertActionStyleCancel
                                                                                            handler:nil]];
                                                    [weakSelf presentViewController:alert animated:YES completion:nil];
                                                }];
}


- (void)login {
    if (![[INatReachability sharedClient] isNetworkReachable]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                                                       message:NSLocalizedString(@"Try again next time you're connected to the Internet.", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
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
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                       message:alertMsg
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    [[Analytics sharedClient] event:kAnalyticsEventOnboardingLoginPressed
                     withProperties:@{ @"mode": @"login" }];
    
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
                                                   if (strongSelf.selectedPartner) {
                                                       [appDelegate.loginController loggedInUserSelectedPartner:strongSelf.selectedPartner
                                                                                                     completion:nil];
                                                   }
                                                   if ([appDelegate.window.rootViewController isKindOfClass:[OnboardingViewController class]]) {
                                                       [appDelegate showMainUI];
                                                   } else {
                                                       [strongSelf dismissViewControllerAnimated:YES completion:nil];
                                                   }
                                                   [[NSNotificationCenter defaultCenter] postNotificationName:kINatLoggedInNotificationKey
                                                                                                       object:nil];
                                               });
                                           } failure:^(NSError *error) {
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   [MBProgressHUD hideAllHUDsForView:hudView animated:YES];
                                               });
                                               
                                               NSString *alertTitle = NSLocalizedString(@"Oops", @"Title error with oops text.");
                                               NSString *alertMsg;
                                               if (error) {
                                                   if ([error.domain isEqualToString:NXOAuth2HTTPErrorDomain] && error.code == 401) {
                                                       alertMsg = NSLocalizedString(@"Incorrect username or password.",
                                                                                    @"Error msg when we get a 401 from the server");
                                                   } else if ([error.domain isEqualToString:NXOAuth2HTTPErrorDomain] && error.code == 403) {
                                                       alertMsg = NSLocalizedString(@"You don't have permission to do that. Your account may have been suspended. Please contact help@inaturalist.org.",
                                                                                    @"403 forbidden message");
                                                   } else {
                                                       alertMsg = error.localizedDescription;
                                                   }
                                               } else {
                                                   alertMsg = NSLocalizedString(@"Failed to login to iNaturalist. Please try again.",
                                                                                @"Unknown iNat login error");
                                               }
                                               UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                                                              message:alertMsg
                                                                                                       preferredStyle:UIAlertControllerStyleAlert];
                                               [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                                                         style:UIAlertActionStyleCancel
                                                                                       handler:nil]];
                                               [weakSelf presentViewController:alert animated:YES completion:nil];
                                               [weakSelf.passwordField setText:@""];
                                               
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
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                   message:alertMsg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"No", nil)
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                // revert to default base URL
                                                [[NSUserDefaults standardUserDefaults] setObject:nil
                                                                                          forKey:kInatCustomBaseURLStringKey];
                                                [[NSUserDefaults standardUserDefaults] synchronize];
                                                [((INaturalistAppDelegate *)[UIApplication sharedApplication].delegate) reconfigureForNewBaseUrl];
                                            }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                // be extremely defensive here. an invalid baseURL shouldn't be possible,
                                                // but if it does happen, nothing in the app will work.
                                                NSURL *partnerURL = [partner baseURL];
                                                if (partnerURL) {
                                                    [[NSUserDefaults standardUserDefaults] setObject:partnerURL.absoluteString
                                                                                              forKey:kInatCustomBaseURLStringKey];
                                                    [[NSUserDefaults standardUserDefaults] synchronize];
                                                    [((INaturalistAppDelegate *)[UIApplication sharedApplication].delegate) reconfigureForNewBaseUrl];
                                                    self.selectedPartner = partner;
                                                }
                                            }]];
    
    if (partner.logo) {
        UIViewController *v = [[UIViewController alloc] init];
        UIImageView *iv = [UIImageView new];
        [v.view addSubview:iv];
        iv.frame = v.view.bounds;
        iv.image = partner.logo;
        iv.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        iv.center = v.view.center;
        iv.contentMode = UIViewContentModeScaleAspectFit;
        
        [alert setValue:v forKey:@"contentViewController"];
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark WebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldLoadRequest:(NSURLRequest *)request {
    if ([request.URL.path hasPrefix:@"/forgot_password"]) {
        return YES;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    // webviews may trigger their delegate methods more than once
    static UIAlertController *alert;
    if (alert) {
        [alert dismissViewControllerAnimated:YES completion:^{
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        alert = nil;
    } else {
        
        NSString *alertTitle = NSLocalizedString(@"Check your email",
                                                 @"title of alert after you reset your password");
        NSString *alertMsg = NSLocalizedString(@"If the email address you entered is associated with an iNaturalist account, you should receive an email at that address with a link to reset your password.",
                                               @"body of alert after you reset your password");
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                       message:alertMsg
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                    [self dismissViewControllerAnimated:YES completion:nil];
                                                }]];


    }
    
    return YES;
}



@end
