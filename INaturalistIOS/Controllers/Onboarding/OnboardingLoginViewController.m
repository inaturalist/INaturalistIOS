//
//  OnboardingLoginViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 8/4/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

@import CoreTelephony;
@import AuthenticationServices;

@import UIColor_HTMLColors;
@import FontAwesomeKit;
@import MBProgressHUD;
@import NXOAuth2Client;
@import BlocksKit;
@import GoogleSignIn;
@import FBSDKLoginKit;

#import <objc/runtime.h>

#import "OnboardingLoginViewController.h"
#import "UIColor+INaturalist.h"
#import "LoginController.h"
#import "INaturalistAppDelegate.h"
#import "OnboardingViewController.h"
#import "UITapGestureRecognizer+InatHelpers.h"
#import "PartnerController.h"
#import "Partner.h"
#import "INatReachability.h"
#import "iNaturalist-Swift.h"

@interface OnboardingLoginViewController () <UITextFieldDelegate, ForgotPasswordDelegate, INatAuthenticationDelegate, ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate>

@property IBOutlet UISegmentedControl *switchContextControl;

@property IBOutlet UIStackView *iNatAuthStackView;

@property IBOutlet UIStackView *textfieldStackView;
@property IBOutlet UITextField *signupUsernameField;
@property IBOutlet UITextField *signupPasswordField;
@property IBOutlet UITextField *signupEmailField;
@property IBOutlet UITextField *loginUsernameField;
@property IBOutlet UITextField *loginPasswordField;

@property IBOutlet UIButton *forgotButton;

@property IBOutlet UIButton *actionButton;

@property IBOutlet UIButton *skipButton;
@property IBOutlet UIButton *closeButton;

@property IBOutlet UIStackView *extraLoginInfoStackView;
@property IBOutlet UILabel *reasonLabel;
@property IBOutlet UILabel *orLabel;
@property IBOutlet UIStackView *externalLoginStackView;
@property IBOutlet FBSDKLoginButton *facebookButton;
@property IBOutlet GIDSignInButton *googleButton;

@property IBOutlet UILabel *termsLabel;

@property ConsentView *licenseDataConsentView;
@property ConsentView *personalInfoConsentView;
@property ConsentView *dataTransferConsentView;

@property ASAuthorizationAppleIDButton *signinWithAppleButton API_AVAILABLE(ios(13.0));

@property NSArray <FAKIcon *> *leftViewIcons;

@property Partner *selectedPartner;

@property UIToolbar *doneToolbar;

@end

@implementation OnboardingLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // design can't be made to accomodate iPhone 4s
    if ([UIScreen mainScreen].bounds.size.height < 568) {
        self.orLabel.hidden = YES;
        self.actionButton.hidden = YES;
    }
    
    self.doneToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                          target:nil
                                                                          action:nil];
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                          target:self
                                                                          action:@selector(kbDoneTapped)];
    self.doneToolbar.items = @[flex, done];
    
    
    self.leftViewIcons = @[
                           ({
                               FAKIcon *email = [FAKIonIcons iosEmailOutlineIconWithSize:30];
                               [email addAttribute:NSForegroundColorAttributeName
                                             value:[UIColor colorWithHexString:@"#4a4a4a"]];
                               email;
                           }),
                           ({
                               FAKIcon *person = [FAKIonIcons iosPersonOutlineIconWithSize:30];
                               [person addAttribute:NSForegroundColorAttributeName
                                              value:[UIColor colorWithHexString:@"#4a4a4a"]];
                               person;
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
                           ({
                               FAKIcon *lock = [FAKIonIcons iosLockedOutlineIconWithSize:30];
                               [lock addAttribute:NSForegroundColorAttributeName
                                            value:[UIColor colorWithHexString:@"#4a4a4a"]];
                               lock;
                           }),
                           ];
    
    NSArray *fields = @[ self.signupEmailField, self.signupUsernameField, self.signupPasswordField, self.loginUsernameField, self.loginPasswordField ];
    [fields enumerateObjectsUsingBlock:^(UITextField *field, NSUInteger idx, BOOL * _Nonnull stop) {
        field.inputAccessoryView = self.doneToolbar;
        
        field.tag = idx;
        field.leftView = ({
            UILabel *label = [UILabel new];
            
            // pin the width for padding
            [label.widthAnchor constraintEqualToConstant:36.0f].active = YES;
            label.textAlignment = NSTextAlignmentCenter;
            label.attributedText = [self.leftViewIcons[idx] attributedString];
                        
            label;
        });
        field.leftViewMode = UITextFieldViewModeAlways;
    }];
    
    self.forgotButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    self.forgotButton.tintColor = [UIColor colorWithHexString:@"#4a4a4a"];
    [self.forgotButton setTitle:NSLocalizedString(@"Forgot password?", @"Title for forgot password button.")
                       forState:UIControlStateNormal];
    
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
    
    self.reasonLabel.text = self.reason;
    
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
            if ([UIApplication.sharedApplication canOpenURL:termsURL]) {
                [UIApplication.sharedApplication openURL:termsURL
                                                 options:@{}
                                       completionHandler:nil];
            }
        } else if ([tapSender didTapAttributedTextInLabel:self.termsLabel inRange:privacyRange]) {
            NSURL *privacyURL = [NSURL URLWithString:@"https://www.inaturalist.org/pages/privacy"];
            if ([UIApplication.sharedApplication canOpenURL:privacyURL]) {
                [UIApplication.sharedApplication openURL:privacyURL
                                                 options:@{}
                                       completionHandler:nil];
            }
        }
    }];
    self.termsLabel.userInteractionEnabled = YES;
    [self.termsLabel addGestureRecognizer:tap];
    
    NSString *learnMore = NSLocalizedString(@"Learn More", @"button to learn more about inat account policies");
    NSString *viewPrivacyPolicy = NSLocalizedString(@"View Privacy Policy", @"button to view privacy policy");
    NSString *viewTermsOfUse = NSLocalizedString(@"View Terms of Use", @"button to view terms of use");
    
    NSString *licenseConsentLabelText = NSLocalizedString(@"Yes, license my content so scientists can use my data.", @"cc licensing consent checkbox label");
    
    self.licenseDataConsentView = [[ConsentView alloc] initWithLabelText:licenseConsentLabelText
                                                           learnMoreText:learnMore
                                                             userConsent:true
                                                         learnMoreAction:^{
        
        NSString *alertTitle = NSLocalizedString(@"Content Licensing", @"Title for About Content Licensing notice during signup");
        NSString *creativeCommons = NSLocalizedString(@"Check this box if you want to apply a Creative Commons Attribution-NonCommercial license to your photos. You can choose a different license or remove the license later, but this is the best license for sharing with researchers.", @"Alert text for the license content checkbox during create account.");

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                       message:creativeCommons
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        
    }];
    
    NSString *piConsentLabelText = NSLocalizedString(@"I consent to allow iNaturalist to store and process limited kinds of personal information about me in order to manage my account.", @"personal info consent checkbox label");
    self.personalInfoConsentView = [[ConsentView alloc] initWithLabelText:piConsentLabelText
                                                            learnMoreText:learnMore
                                                              userConsent:false
                                                          learnMoreAction:^{
        
        NSString *alertTitle = NSLocalizedString(@"Personal Information", @"Title for About Personal Information notice during signup");
        NSString *piMore = NSLocalizedString(@"We store personal information like usernames and email addresses in order to manage accounts on this site, and to comply with privacy laws, we need you to check this box to indicate that you consent to this use of personal information. To learn more about what information we collect and how we use it, please see our Privacy Policy and our Terms of Use. There is no way to have an iNaturalist account without storing personal information, so the only way to revoke this consent is to delete your account.", @"Alert text for the personal information checkbox during create account.");

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                       message:piMore
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:viewPrivacyPolicy style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSURL *privacyURL = [NSURL URLWithString:@"https://www.inaturalist.org/pages/privacy"];
            [[UIApplication sharedApplication] openURL:privacyURL options:@{} completionHandler:nil];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:viewTermsOfUse style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSURL *termsURL = [NSURL URLWithString:@"https://www.inaturalist.org/pages/terms"];
            [[UIApplication sharedApplication] openURL:termsURL options:@{} completionHandler:nil];
        }]];

        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }];
    
    NSString *dtConsentLabelText = NSLocalizedString(@"I consent to allow my personal information to be transferred to the United States of America.", @"data transfer consent checkbox label");
    self.dataTransferConsentView = [[ConsentView alloc] initWithLabelText:dtConsentLabelText
                                                            learnMoreText:learnMore
                                                              userConsent:false
                                                          learnMoreAction:^{
        
        NSString *alertTitle = NSLocalizedString(@"Data Transfer", @"Title for About Data Transfer notice during signup");
        NSString *dtMore = NSLocalizedString(@"Some data privacy laws, like the European Union's General Data Protection Regulation (GDPR), require explicit consent to transfer personal information from their jurisdictions to other jurisdictions where the legal protection of this information is not considered adequate. As of 2020, the European Union no longer considers the United States to be a jurisdiction that provides adequate legal protection of personal information, specifically because of the possibility of the US government surveilling data entering the US. It is possible other jurisdictions may have the same opinion. Using iNaturalist requires the storage of personal information like your email address, all iNaturalist data is stored in the United States, and we cannot be sure what legal jurisdiction you are in when you are using iNaturalist, so in order to comply with privacy laws like the GDPR, you must acknowledge that you understand and accept this risk and consent to transferring your personal information to iNaturalist's servers in the US. To learn more about what information we collect and how we use it, please see our Privacy Policy and our Terms of Use. There is no way to have an iNaturalist account without storing personal information, so the only way to revoke this consent is to delete your account.", @"Alert text for the data transfer consent checkbox during create account.");

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                       message:dtMore
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:viewPrivacyPolicy style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSURL *privacyURL = [NSURL URLWithString:@"https://www.inaturalist.org/pages/privacy"];
            [[UIApplication sharedApplication] openURL:privacyURL options:@{} completionHandler:nil];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:viewTermsOfUse style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSURL *termsURL = [NSURL URLWithString:@"https://www.inaturalist.org/pages/terms"];
            [[UIApplication sharedApplication] openURL:termsURL options:@{} completionHandler:nil];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }];
    
    [self.iNatAuthStackView insertArrangedSubview:self.licenseDataConsentView atIndex:4];
    [self.iNatAuthStackView insertArrangedSubview:self.personalInfoConsentView atIndex:5];
    [self.iNatAuthStackView insertArrangedSubview:self.dataTransferConsentView atIndex:6];

    [self.licenseDataConsentView.widthAnchor constraintEqualToAnchor:self.iNatAuthStackView.widthAnchor].active = YES;
    [self.personalInfoConsentView.widthAnchor constraintEqualToAnchor:self.iNatAuthStackView.widthAnchor].active = YES;
    [self.dataTransferConsentView.widthAnchor constraintEqualToAnchor:self.iNatAuthStackView.widthAnchor].active = YES;
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.loginController.delegate = self;
    self.facebookButton.delegate = appDelegate.loginController;
    // ensure we're unauthenticated from facebook
    if ([FBSDKAccessToken currentAccessToken]) {
        FBSDKLoginManager *fb = [[FBSDKLoginManager alloc] init];
        [fb logOut];
    }
    
    [self.googleButton addTarget:self
                          action:@selector(handleAuthorizationGoogleButtonPress)
                forControlEvents:UIControlEventTouchUpInside];
    
    // ensure we're unauthenticated from google
    if ([GIDSignIn.sharedInstance hasPreviousSignIn]) {
        [GIDSignIn.sharedInstance signOut];
    }
    
    
    if (@available(iOS 13.0, *)) {
        // make some room for the apple button
        [self.googleButton setStyle:kGIDSignInButtonStyleIconOnly];
        
        // add the apple button
        self.signinWithAppleButton = [[ASAuthorizationAppleIDButton alloc] init];
        [self.signinWithAppleButton addTarget:self
                                  action:@selector(handleAuthorizationAppleIDButtonPress)
                        forControlEvents:UIControlEventTouchUpInside];
        [self.externalLoginStackView insertArrangedSubview:self.signinWithAppleButton atIndex:0];
        
        // setup the height anchors, even though facebook for some bizarre reason
        [self.signinWithAppleButton.heightAnchor constraintEqualToConstant:44].active = YES;
        [self.googleButton.heightAnchor constraintEqualToConstant:44].active = YES;
        [self.facebookButton.heightAnchor constraintEqualToConstant:44].active = YES;
    }
    
    self.signupUsernameField.placeholder = NSLocalizedString(@"Username", @"The desired username during signup.");
    self.loginUsernameField.placeholder = NSLocalizedString(@"Username or email", @"users can login with their username or their email address.");
    self.loginPasswordField.rightViewMode = UITextFieldViewModeUnlessEditing;
    self.signupPasswordField.rightViewMode = UITextFieldViewModeNever;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.startsInLoginMode) {
        self.switchContextControl.selectedSegmentIndex = 1;
        [self setLoginContext];
    } else {
        [self setSignupContext];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    PartnerController *partners = [[PartnerController alloc] init];
    
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    if (info) {
        for (CTCarrier *carrier in info.serviceSubscriberCellularProviders.allValues) {
            // I guess just show one? There doesn't seem to be a way to prefer the "home"
            // network, and since this is a dictionary, there's no preferred order.
            Partner *p = [partners partnerForMobileCountryCode:carrier.mobileCountryCode];
            if (p) {
                [self showPartnerAlertForPartner:p];
                break;
            }
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.signupEmailField) {
        [self.signupUsernameField becomeFirstResponder];
    } else if (textField == self.signupUsernameField) {
        [self.signupPasswordField becomeFirstResponder];
    } else if (textField == self.loginUsernameField) {
        [self.loginPasswordField becomeFirstResponder];
    } else if (textField == self.signupPasswordField || self.loginPasswordField) {
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

- (void)kbDoneTapped {
    [self.view endEditing:YES];
}

- (IBAction)actionPressed:(id)sender {
    if (self.textfieldStackView.arrangedSubviews.count == 2) {
        [self login];
    } else {
        [self signup];
    }
}

- (IBAction)forgotPressed:(id)sender {
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
    
    ForgotPasswordController *forgot = [[ForgotPasswordController alloc] init];
    forgot.delegate = self;
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] bk_initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                              handler:^(id sender) {
                                                                                  [self dismissViewControllerAnimated:YES
                                                                                                                 completion:nil];
                                                                              }];
    forgot.navigationItem.leftBarButtonItem = cancel;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:forgot];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)setLoginContext {
    for (UITextField *field in @[ self.signupEmailField, self.signupUsernameField, self.signupPasswordField ]) {
        [self.textfieldStackView removeArrangedSubview:field];
        field.hidden = YES;
    }
    
    for (UITextField *field in @[ self.loginUsernameField, self.loginPasswordField ]) {
        [self.textfieldStackView addArrangedSubview:field];
        field.hidden = NO;
    }
        
    [self.iNatAuthStackView insertArrangedSubview:self.forgotButton
                                          atIndex:3];
    self.forgotButton.hidden = NO;
    
    [self.actionButton setTitle:NSLocalizedString(@"Log In", nil)
                       forState:UIControlStateNormal];
    
    [self.extraLoginInfoStackView insertArrangedSubview:self.orLabel atIndex:1];
    [self.extraLoginInfoStackView insertArrangedSubview:self.externalLoginStackView atIndex:2];
    self.orLabel.hidden = NO;
    self.externalLoginStackView.hidden = NO;
    
    [self.iNatAuthStackView removeArrangedSubview:self.licenseDataConsentView];
    [self.iNatAuthStackView removeArrangedSubview:self.personalInfoConsentView];
    [self.iNatAuthStackView removeArrangedSubview:self.dataTransferConsentView];
    self.licenseDataConsentView.hidden = YES;
    self.personalInfoConsentView.hidden = YES;
    self.dataTransferConsentView.hidden = YES;
}

- (void)setSignupContext {
    for (UITextField *field in @[ self.loginUsernameField, self.loginPasswordField ]) {
        [self.textfieldStackView removeArrangedSubview:field];
        field.hidden = YES;
    }
    
    for (UITextField *field in @[ self.signupEmailField, self.signupUsernameField, self.signupPasswordField ]) {
        [self.textfieldStackView addArrangedSubview:field];
        field.hidden = NO;
    }
    
    [self.iNatAuthStackView removeArrangedSubview:self.forgotButton];
    self.forgotButton.hidden = YES;
    
    [self.actionButton setTitle:NSLocalizedString(@"Sign Up", nil)
                       forState:UIControlStateNormal];
    
    [self.extraLoginInfoStackView removeArrangedSubview:self.orLabel];
    [self.extraLoginInfoStackView removeArrangedSubview:self.externalLoginStackView];
    self.externalLoginStackView.hidden = YES;
    self.orLabel.hidden = YES;
    
    [self.iNatAuthStackView addArrangedSubview:self.licenseDataConsentView];
    [self.iNatAuthStackView addArrangedSubview:self.personalInfoConsentView];
    [self.iNatAuthStackView addArrangedSubview:self.dataTransferConsentView];
    self.licenseDataConsentView.hidden = NO;
    self.personalInfoConsentView.hidden = NO;
    self.dataTransferConsentView.hidden = NO;
}

- (IBAction)switchAuthContext:(UISegmentedControl *)segmentedControl {
    // clear text fields and resign keyboard
    // when switching context
    NSArray *allFields = @[
        self.loginUsernameField,
        self.loginPasswordField,
        self.signupEmailField,
        self.signupUsernameField,
        self.signupPasswordField,
    ];
    
    for (UITextField *field in allFields) {
        if (field != self.signupPasswordField) {
            // don't clear the signup password field
            // since this can be a suggested "strong
            // password" from apple
            field.text = @"";
        }
        [field resignFirstResponder];
    }
    
    if (segmentedControl.selectedSegmentIndex == 0) {
        [self setSignupContext];
    } else {
        [self setLoginContext];
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

- (void)handleAuthorizationGoogleButtonPress {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
    LoginController *login = appDelegate.loginController;
    [login loginWithGoogleWithPresentingVC:self];
}

- (void)handleAuthorizationAppleIDButtonPress {
    if (@available(iOS 13.0, *)) {
        ASAuthorizationAppleIDProvider *provider = [[ASAuthorizationAppleIDProvider alloc] init];
        ASAuthorizationAppleIDRequest *request = [provider createRequest];
        request.requestedScopes = @[ASAuthorizationScopeEmail, ASAuthorizationScopeFullName];
        
        ASAuthorizationController *authController = [[ASAuthorizationController alloc] initWithAuthorizationRequests:@[ request ]];
        
        INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
        authController.delegate = appDelegate.loginController;
        authController.presentationContextProvider = self;
        [authController performRequests];
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
    if (!self.signupEmailField.text || [self.signupEmailField.text rangeOfString:@"@"].location == NSNotFound) {
        isValid = NO;
        alertMsg = NSLocalizedString(@"Invalid Email Address", "Error for bad email when making account.");
    }  else if (!self.signupPasswordField.text || self.signupPasswordField.text.length < INatMinPasswordLength) {
        isValid = NO;
        alertMsg = NSLocalizedString(@"Passwords must be at least six characters in length.",
                                     @"Error for bad password when making account");
    } else if (!self.signupUsernameField.text) {
        isValid = NO;
        alertMsg = NSLocalizedString(@"Invalid Username", @"Error for bad username when making account.");
    } else if (!self.personalInfoConsentView.userConsent) {
        isValid = NO;
        alertMsg = NSLocalizedString(@"There is no way to have an iNaturalist account without storing personal information.", @"Error for no personal info consent when making account.");
    } else if (!self.dataTransferConsentView.userConsent) {
        isValid = NO;
        alertMsg = NSLocalizedString(@"There is no way to have an iNaturalist account without storing personal information in the United States.", @"Error for no data transfer consent consent when making account.");
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
        
    NSString *license = self.licenseDataConsentView.userConsent ? @"CC-BY-NC" : @"";
    NSInteger selectedPartnerId = self.selectedPartner ? self.selectedPartner.identifier : 1;
        
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate.loginController createAccountWithEmail:self.signupEmailField.text
                                               password:self.signupPasswordField.text
                                               username:self.signupUsernameField.text
                                                   site:selectedPartnerId
                                                license:license];
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
    if (!self.loginUsernameField.text) {
        isValid = NO;
        alertMsg = NSLocalizedString(@"Invalid Username",
                                     @"Error for bad username when making account.");
    }
    if (!self.loginPasswordField.text || self.loginPasswordField.text.length < INatMinPasswordLength) {
        isValid = NO;
        alertMsg = NSLocalizedString(@"Passwords must be at least six characters in length.",
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
            
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate.loginController loginWithUsername:self.loginUsernameField.text
                                          password:self.loginPasswordField.text];
}

#pragma mark - Partner alert helper

- (void)showPartnerAlertForPartner:(Partner *)partner {
    if (!partner) { return; }
        
    NSString *alertTitle = [NSString stringWithFormat:NSLocalizedString(@"Join %@?",
                                                                        @"join iNat network partner alert title"),
                            partner.shortName];
    
   

    NSString *alertMsgFmt = NSLocalizedString(@"%@ is part of the international iNaturalist Network. Would you like to join %@ to localize your experience of iNaturalist and share data with local institutions?",
                                              @"join iNat network partner alert message - %1%@ is the country name, %2%@ is partner name");
    NSString *alertMsg = [NSString stringWithFormat:alertMsgFmt, partner.countryName, partner.name];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                   message:alertMsg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"No",
                                                                      @"Generic negative response to a yes/no question")
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                // revert to default base URL
                                                [[NSUserDefaults standardUserDefaults] setObject:nil
                                                                                          forKey:kInatCustomBaseURLStringKey];
                                                [[NSUserDefaults standardUserDefaults] synchronize];
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

- (void)finishedWithForgotPasswordController:(ForgotPasswordController *)forgotPasswordController {
    [self dismissViewControllerAnimated:YES completion:nil];
    
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
    
    [self presentViewController:alert animated:true completion:nil];
}

#pragma mark - INatAuthenticationDelegate

// sometimes we have to delay finishing new account setup due to
// an indexing delay
- (void)delayForSettingUpAccount {
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = NSLocalizedString(@"Setting up iNaturalist account...",
                                          @"Notice while we're setting up an iNat account for them");
        hud.dimBackground = YES;
        hud.removeFromSuperViewOnHide = YES;
    });
}

- (void)loginFailedWithError:(NSError *)error {
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];

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
        alertMsg = NSLocalizedString(@"Failed to log in to iNaturalist. Please try again.",
                                     @"Unknown iNat login error");
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                   message:alertMsg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
    [self.loginPasswordField setText:@""];
    [self.signupPasswordField setText:@""];
}

- (void)loginSuccess {
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];

    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.selectedPartner) {
            [appDelegate.loginController loggedInUserSelectedPartner:self.selectedPartner
                                                          completion:nil];
        }
        if ([appDelegate.window.rootViewController isKindOfClass:[OnboardingViewController class]]) {
            [appDelegate showMainUI];
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    });
}

#pragma mark - ASAuthorizationControllerPresentationContextProviding

- (ASPresentationAnchor)presentationAnchorForAuthorizationController:(ASAuthorizationController *)controller  API_AVAILABLE(ios(13.0)) {
    return self.view.window;
}


@end
