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
#import "IconAndTextControl.h"
#import "Analytics.h"
#import "PartnerController.h"
#import "Partner.h"
#import "INatWebController.h"
#import "INatReachability.h"
#import "LoginSwitchContextButton.h"

@interface OnboardingLoginViewController () <UITextFieldDelegate, INatWebControllerDelegate, INatAuthenticationDelegate, GIDSignInUIDelegate, ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate>

@property IBOutlet UILabel *titleLabel;

@property IBOutlet UIStackView *iNatAuthStackView;

@property IBOutlet UIStackView *textfieldStackView;
@property IBOutlet UITextField *signupUsernameField;
@property IBOutlet UITextField *signupPasswordField;
@property IBOutlet UITextField *signupEmailField;
@property IBOutlet UITextField *loginUsernameField;
@property IBOutlet UITextField *loginPasswordField;

@property IBOutlet UIButton *forgotButton;

@property IBOutlet UIStackView *licenseStackView;
@property IBOutlet UIButton *licenseMyDataButton;

@property IBOutlet UIButton *actionButton;
@property IBOutlet LoginSwitchContextButton *switchContextButton;

@property IBOutlet UIButton *skipButton;
@property IBOutlet UIButton *closeButton;

@property IBOutlet UILabel *reasonLabel;
@property IBOutlet UILabel *orLabel;
@property IBOutlet UIStackView *externalLoginStackView;
@property IBOutlet FBSDKLoginButton *facebookButton;
@property IBOutlet GIDSignInButton *googleButton;

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
    
    FAKIcon *check = [FAKIonIcons iosCheckmarkOutlineIconWithSize:30];
    [self.licenseMyDataButton setAttributedTitle:check.attributedString
                                        forState:UIControlStateNormal];
    self.licenseMyData = YES;
    
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
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.loginController.delegate = self;
    self.facebookButton.delegate = appDelegate.loginController;
    // ensure we're unauthenticated from facebook
    if ([FBSDKAccessToken currentAccessToken]) {
        FBSDKLoginManager *fb = [[FBSDKLoginManager alloc] init];
        [fb logOut];
    }
    
    // a ui delegate is required
    GIDSignIn.sharedInstance.uiDelegate = self;
    // ensure we're unauthenticated from google
    if ([[GIDSignIn sharedInstance] hasAuthInKeychain]) {
        [[GIDSignIn sharedInstance] signOut];
    }
    
    if (@available(iOS 13.0, *)) {
        // make some room for the apple button
        [self.googleButton setStyle:kGIDSignInButtonStyleIconOnly];
        
        // add the apple button
        ASAuthorizationAppleIDButton *signinWithAppleButton = [[ASAuthorizationAppleIDButton alloc] init];
        [signinWithAppleButton addTarget:self
                                  action:@selector(handleAuthorizationAppleIDButtonPress)
                        forControlEvents:UIControlEventTouchUpInside];
        [self.externalLoginStackView insertArrangedSubview:signinWithAppleButton atIndex:0];
        
        // setup the height anchors, even though facebook for some bizarre reason
        [signinWithAppleButton.heightAnchor constraintEqualToConstant:44].active = YES;
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
        if (@available(iOS 12.0, *)) {
            for (CTCarrier *carrier in info.serviceSubscriberCellularProviders.allValues) {
                // I guess just show one? There doesn't seem to be a way to prefer the "home"
                // network, and since this is a dictionary, there's no preferred order.
                Partner *p = [partners partnerForMobileCountryCode:carrier.mobileCountryCode];
                if (p) {
                    [self showPartnerAlertForPartner:p];
                    break;
                }
            }
        } else {
            CTCarrier *carrier = info.subscriberCellularProvider;
            if (carrier) {
                Partner *p = [partners partnerForMobileCountryCode:carrier.mobileCountryCode];
                if (p) {
                    [self showPartnerAlertForPartner:p];
                }
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
    
    INatWebController *webController = [[INatWebController alloc] init];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/forgot_password.mobile", INatWebBaseURL]];
    [webController setUrl:url];
    webController.delegate = self;
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] bk_initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                              handler:^(id sender) {
                                                                                  [self dismissViewControllerAnimated:YES
                                                                                                                 completion:nil];
                                                                              }];
    webController.navigationItem.leftBarButtonItem = cancel;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:webController];
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
                                          atIndex:2];
    self.forgotButton.hidden = NO;
    
    self.titleLabel.text = NSLocalizedString(@"Log In", nil);
    [self.actionButton setTitle:NSLocalizedString(@"Log In", nil)
                       forState:UIControlStateNormal];
    
    self.licenseStackView.hidden = YES;
    [self.switchContextButton setContext:LoginContextLogin];
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
    
    self.titleLabel.text = NSLocalizedString(@"Sign Up", nil);
    [self.actionButton setTitle:NSLocalizedString(@"Sign Up", nil)
                       forState:UIControlStateNormal];
    self.licenseStackView.hidden = NO;
    [self.switchContextButton setContext:LoginContextSignup];
}

- (IBAction)switchAuthContext:(id)sender {
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
    
    if (self.textfieldStackView.arrangedSubviews.count == 3) {
        [self setLoginContext];
    } else {
        [self setSignupContext];
    }
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
    
    NSString *license = self.licenseMyData ? @"CC-BY-NC" : @"";
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
    
    [[Analytics sharedClient] event:kAnalyticsEventOnboardingLoginPressed
                     withProperties:@{ @"mode": @"login" }];
        
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate.loginController loginWithUsername:self.loginUsernameField.text
                                          password:self.loginPasswordField.text];
}

#pragma mark - Partner alert helper

- (void)showPartnerAlertForPartner:(Partner *)partner {
    if (!partner) { return; }
    
    [[Analytics sharedClient] event:kAnalyticsEventPartnerAlertPresented
                     withProperties:@{ @"Partner": partner.name }];
    
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
        alertMsg = NSLocalizedString(@"Failed to login to iNaturalist. Please try again.",
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
