//
//  SignupSplashViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/14/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

@import CoreTelephony;

#import <FontAwesomeKit/FAKIonIcons.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <objc/runtime.h>

#import "SignupSplashViewController.h"
#import "NSAttributedString+InatHelpers.h"
#import "INaturalistAppDelegate.h"
#import "LoginController.h"
#import "SignupViewController.h"
#import "UIColor+INaturalist.h"
#import "SplitTextButton.h"
#import "FAKInaturalist.h"
#import "LoginViewController.h"
#import "PartnerController.h"
#import "Partner.h"
#import "Analytics.h"

static char PARTNER_ASSOCIATED_KEY;

@interface SignupSplashViewController () <UIAlertViewDelegate> {
    UIImage *orangeFlower, *moth, *purpleFlower;
    NSTimer *backgroundCycleTimer;
    
    BOOL _skippable;
    BOOL _cancellable;
    NSString *_reason;
    
    NSArray *constraintsForCompactClass;
    NSArray *constraintsForRegularClass;
    
    UIAlertView *partnerAlert;
}
@property Partner *selectedPartner;
@end

@implementation SignupSplashViewController

#pragma mark - UIViewController lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // cancellable requires the navigation bar
    [self.navigationController setNavigationBarHidden:!self.cancellable animated:NO];
    
    // setup custom navigation bar style
    // white button tint
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setTitleTextAttributes:@{
                                                                      NSForegroundColorAttributeName:
                                                                      [UIColor whiteColor]
                                                                      }];
    
    // completely clear navbar background
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    [self.navigationController.navigationBar setTranslucent:YES];
    
    if (self.animateIn) {
        self.loginFaceButton.alpha = 0.0f;
        self.loginGButton.alpha = 0.0f;
        self.skipButton.alpha = 0.0f;
        self.signinEmailButton.alpha = 0.0f;
        self.signupEmailButton.alpha = 0.0f;
    }
    
    if (self.backgroundImageView && orangeFlower)
        [self.backgroundImageView setImage:orangeFlower];
    
    __weak typeof(self)weakSelf = self;
    backgroundCycleTimer = [NSTimer bk_scheduledTimerWithTimeInterval:4.0f
                                                                block:^(NSTimer *timer) {
                                                                    __strong typeof(weakSelf)strongSelf = weakSelf;
                                                                    UIImage *newImage;
                                                                    if (strongSelf.backgroundImageView.image == orangeFlower) {
                                                                        newImage = moth;
                                                                    } else if (strongSelf.backgroundImageView.image == moth) {
                                                                        newImage = purpleFlower;
                                                                    } else {
                                                                        newImage = orangeFlower;
                                                                    }
                                                                    [UIView transitionWithView:strongSelf.backgroundImageView
                                                                                      duration:1.0f
                                                                                       options:UIViewAnimationOptionTransitionCrossDissolve
                                                                                    animations:^{
                                                                                        strongSelf.backgroundImageView.image = newImage;
                                                                                    }
                                                                                    completion:NULL];
                                                                }
                                                              repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [backgroundCycleTimer invalidate];
    backgroundCycleTimer = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.animateIn) {
        // only do this once
        self.animateIn = NO;
        
        [UIView animateWithDuration:0.3f
                         animations:^{
                             self.loginFaceButton.alpha = 1.0f;
                             self.loginGButton.alpha = 1.0f;
                             self.signupEmailButton.alpha = 1.0f;
                             self.signinEmailButton.alpha = 1.0f;
                         }];
        
        __weak typeof(self)weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf)strongSelf = weakSelf;
            [UIView animateWithDuration:0.3f
                             animations:^{
                                 strongSelf.skipButton.alpha = 1.0f;
                             }];
        });
    }
    
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
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage *closeImage = ({
        FAKIcon *close = [FAKIonIcons iosCloseEmptyIconWithSize:40];
        [close addAttribute:NSForegroundColorAttributeName
                      value:[UIColor whiteColor]];
        [close imageWithSize:CGSizeMake(40, 40)];
    });
    
    __weak typeof(self)weakSelf = self;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] bk_initWithImage:closeImage
                                                                                 style:UIBarButtonItemStylePlain
                                                                               handler:^(id sender) {
                                                                                   [[Analytics sharedClient] event:kAnalyticsEventSplashCancel];
                                                                                   [weakSelf dismissViewControllerAnimated:YES
                                                                                                                completion:nil];
                                                                               }];
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor whiteColor];
    
    orangeFlower = [UIImage imageNamed:@"SignUp_OrangeFlower.jpg"];
    moth = [UIImage imageNamed:@"SignUp_Moth.jpg"];
    purpleFlower = [UIImage imageNamed:@"SignUp_PurpleFlower.jpg"];
    
    self.backgroundImageView = ({
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
        iv.translatesAutoresizingMaskIntoConstraints = NO;
        
        iv.contentMode = UIViewContentModeScaleAspectFill;
        iv.image = orangeFlower;
        
        iv;
    });
    [self.view addSubview:self.backgroundImageView];
    
    
    if (self.reason) {
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
            self.blurView = ({
                UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
                
                UIVisualEffectView *view = [[UIVisualEffectView alloc] initWithEffect:blur];
                view.frame = self.view.bounds;
                view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
                
                view;
            });
        } else {
            self.blurView = ({
                UIView *view = [[UIView alloc] initWithFrame:self.view.bounds];
                view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
                
                view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6f];
                
                view;
            });
        }
        [self.view addSubview:self.blurView];
    }

    
    self.logoLabel = ({
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        
        int logoSize;
        if ([self respondsToSelector:@selector(traitCollection)]) {
            if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
                logoSize = 200;
            } else {
                logoSize = 160;
            }
        } else {
            logoSize = 160;
        }
        FAKINaturalist *logo = [FAKINaturalist inatWordmarkIconWithSize:logoSize];
        [logo addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
        
        label.textAlignment = NSTextAlignmentCenter;
        label.attributedText = logo.attributedString;
        
        label;
    });
    [self.view addSubview:self.logoLabel];
    
    self.reasonLabel = ({
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        
        label.numberOfLines = 0;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:15.0f];
        label.textAlignment = NSTextAlignmentCenter;
        
        if (self.reason && self.reason.length > 0) {
            label.text = self.reason;
        } else {
            label.hidden = YES;
        }
        
        label;
    });
    [self.view addSubview:self.reasonLabel];
    
    NSMutableParagraphStyle *indentedParagraphStyle = ({
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        style.alignment = NSTextAlignmentJustified;
        style.firstLineHeadIndent = 10.0f;
        style.headIndent = 10.0f;
        style.tailIndent = -10.0f;
        style;
    });

    self.loginFaceButton = ({
        SplitTextButton *button = [[SplitTextButton alloc] initWithFrame:CGRectZero];
        button.trailingTitleLabel.textAlignment = NSTextAlignmentNatural;
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        button.leadingTitleLabel.attributedText = ({
            FAKIcon *face = [FAKIonIcons socialFacebookIconWithSize:25.0f];
            face.attributedString;
        });

        
        NSAttributedString *title = [NSAttributedString inat_attrStrWithBaseStr:NSLocalizedString(@"Log In with Facebook", "@base text for fb login button")
                                                                      baseAttrs:@{
                                                                                  NSFontAttributeName: [UIFont systemFontOfSize:16.0f],
                                                                                  NSParagraphStyleAttributeName: indentedParagraphStyle,
                                                                                  }
                                                                       emSubstr:NSLocalizedString(@"Facebook", @"portion of the base text for fb login button that is bold. must be a substring of the base test.")
                                                                        emAttrs:@{ NSFontAttributeName: [UIFont boldSystemFontOfSize:16.0f] }];
        button.trailingTitleLabel.attributedText = title;
        
        __weak typeof(self)weakSelf = self;
        [button bk_addEventHandler:^(id sender) {
            [[Analytics sharedClient] event:kAnalyticsEventSplashFacebook];
            
            if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                            message:NSLocalizedString(@"Try again next time you're connected to the Internet.", nil)
                                           delegate:nil
                                  cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                  otherButtonTitles:nil] show];
                return;
            }
            
            INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate.loginController loginWithFacebookSuccess:^(NSDictionary *info) {
                __strong typeof(weakSelf)strongSelf = weakSelf;
                if ([appDelegate.window.rootViewController isEqual:strongSelf.navigationController]) {
                    [appDelegate showMainUI];
                } else {
                    [weakSelf dismissViewControllerAnimated:YES completion:nil];
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

        } forControlEvents:UIControlEventTouchUpInside];
        
        button;
    });
    [self.view addSubview:self.loginFaceButton];
    
    self.loginGButton = ({
        SplitTextButton *button = [[SplitTextButton alloc] initWithFrame:CGRectZero];
        button.trailingTitleLabel.textAlignment = NSTextAlignmentNatural;
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        button.leadingTitleLabel.attributedText = ({
            FAKIcon *face = [FAKIonIcons socialGoogleplusIconWithSize:25.0f];
            face.attributedString;
        });
        NSAttributedString *title = [NSAttributedString inat_attrStrWithBaseStr:NSLocalizedString(@"Log In with Google+", "@base text for g+ login button")
                                                                      baseAttrs:@{
                                                                                  NSFontAttributeName: [UIFont systemFontOfSize:16.0f],
                                                                                  NSParagraphStyleAttributeName: indentedParagraphStyle,
                                                                                  }
                                                                       emSubstr:NSLocalizedString(@"Google+", @"portion of the base text for g+ login button that is bold. must be a substring of the base test.")
                                                                        emAttrs:@{ NSFontAttributeName: [UIFont boldSystemFontOfSize:16.0f] }];
        
        button.trailingTitleLabel.attributedText = title;
        
        __weak typeof(self)weakSelf = self;
        [button bk_addEventHandler:^(id sender) {
            [[Analytics sharedClient] event:kAnalyticsEventSplashGoogle];

            __strong typeof(weakSelf)strongSelf = weakSelf;
            
            if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                            message:NSLocalizedString(@"Try again next time you're connected to the Internet.", nil)
                                           delegate:nil
                                  cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                  otherButtonTitles:nil] show];
                return;
            }
            
            INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate.loginController loginWithGoogleUsingNavController:strongSelf.navigationController
                                                                   success:^(NSDictionary *info) {
                                                                       __strong typeof(weakSelf)strongSelf = weakSelf;
                                                                       
                                                                       if ([appDelegate.window.rootViewController isEqual:strongSelf.navigationController]) {
                                                                           [appDelegate showMainUI];
                                                                       } else {
                                                                           
                                                                           [weakSelf dismissViewControllerAnimated:YES completion:nil];
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
                        
        } forControlEvents:UIControlEventTouchUpInside];

        button;
    });
    [self.view addSubview:self.loginGButton];
    
    self.signupEmailButton = ({
        SplitTextButton *button = [[SplitTextButton alloc] initWithFrame:CGRectZero];
        button.trailingTitleLabel.textAlignment = NSTextAlignmentNatural;
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        button.leadingTitleLabel.attributedText = ({
            FAKIcon *face = [FAKIonIcons emailIconWithSize:25.0f];
            face.attributedString;
        });
        NSAttributedString *title = [NSAttributedString inat_attrStrWithBaseStr:NSLocalizedString(@"Sign Up with Email", "@base text for email signup button")
                                                                      baseAttrs:@{
                                                                                  NSFontAttributeName: [UIFont systemFontOfSize:16.0f],
                                                                                  NSParagraphStyleAttributeName: indentedParagraphStyle,
                                                                                  }
                                                                       emSubstr:NSLocalizedString(@"Email", @"portion of the base text for email signup button that is bold. must be a substring of the base test.")
                                                                        emAttrs:@{ NSFontAttributeName: [UIFont boldSystemFontOfSize:16.0f] }];
        button.trailingTitleLabel.attributedText = title;
        
        __weak typeof(self)weakSelf = self;
        [button bk_addEventHandler:^(id sender) {
            [[Analytics sharedClient] event:kAnalyticsEventSplashSignupEmail];

            __strong typeof(weakSelf)strongSelf = weakSelf;
            SignupViewController *signupVC = [[SignupViewController alloc] initWithNibName:nil bundle:nil];
            signupVC.backgroundImage = strongSelf.backgroundImageView.image;
            signupVC.selectedPartner = strongSelf.selectedPartner;
            [strongSelf.navigationController pushViewController:signupVC animated:YES];
            
        } forControlEvents:UIControlEventTouchUpInside];
        
        button;
    });
    [self.view addSubview:self.signupEmailButton];
    
    self.skipButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        button.tintColor = [UIColor whiteColor];
        
        [button setTitle:NSLocalizedString(@"Skip ›", @"title for skip button during signup prompt")
                forState:UIControlStateNormal];
        
        button.hidden = !self.skippable;
        button.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3f].CGColor;
        button.layer.borderWidth = 1.0f;
        button.layer.cornerRadius = 15;
        
        button.contentEdgeInsets = UIEdgeInsetsMake(-5, 15, -5, 15);
        if ([button respondsToSelector:@selector(setLayoutMargins:)])
            button.layoutMargins = UIEdgeInsetsMake(50, 0, 50, 0);
        
        __weak typeof(self)weakSelf = self;
        [button bk_addEventHandler:^(id sender) {
            [[Analytics sharedClient] event:kAnalyticsEventSplashSkip];

            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (strongSelf.skipAction) {
                strongSelf.skipAction();
            }
        } forControlEvents:UIControlEventTouchUpInside];
        
        button;
    });
    [self.view addSubview:self.skipButton];
    
    self.signinEmailButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        button.tintColor = [UIColor whiteColor];
        [button setAttributedTitle:[NSAttributedString inat_attrStrWithBaseStr:NSLocalizedString(@"Already have an account? Log In", "@base text for email sign in button")
                                                                     baseAttrs:@{
                                                                                 NSFontAttributeName: [UIFont systemFontOfSize:14.0f],
                                                                                 NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent:0.5f],
                                                                                 }
                                                                      emSubstr:NSLocalizedString(@"Log In", @"portion of the base text for email sign in button that is bold. must be a substring of the base test.")
                                                                       emAttrs:@{
                                                                                 NSFontAttributeName: [UIFont boldSystemFontOfSize:14.0f],
                                                                                 NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent:1.0f],
                                                                                 }]
                          forState:UIControlStateNormal];
        
        button.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1f];
        
        __weak typeof(self)weakSelf = self;
        [button bk_addEventHandler:^(id sender) {
            [[Analytics sharedClient] event:kAnalyticsEventNavigateLogin
                             withProperties:@{ @"from": @"SignupSplash" }];
            __strong typeof(weakSelf)strongSelf = weakSelf;
            LoginViewController *login = [[LoginViewController alloc] initWithNibName:nil bundle:nil];
            login.cancellable = NO;
            login.backgroundImage = strongSelf.backgroundImageView.image;
            login.selectedPartner = strongSelf.selectedPartner;
            [strongSelf.navigationController pushViewController:login animated:YES];
        } forControlEvents:UIControlEventTouchUpInside];
        
        button;
    });
    [self.view addSubview:self.signinEmailButton];
    
    NSDictionary *views = @{
                            @"logo": self.logoLabel,
                            @"bg": self.backgroundImageView,
                            @"face": self.loginFaceButton,
                            @"g": self.loginGButton,
                            @"emailSignup": self.signupEmailButton,
                            @"skip": self.skipButton,
                            @"emailSignin": self.signinEmailButton,
                            @"reason": self.reasonLabel,
                            };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[logo]-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[bg]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[bg]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[reason]-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.loginFaceButton
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1.0f
                                                           constant:290.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.loginGButton
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:nil
                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                         multiplier:1.0f
                                                           constant:290.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.signupEmailButton
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:nil
                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                         multiplier:1.0f
                                                           constant:290.0f]];

    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.loginFaceButton
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.loginGButton
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.signupEmailButton
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0f
                                                           constant:0.0f]];

    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.skipButton
                                                         attribute:NSLayoutAttributeCenterX
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.view
                                                         attribute:NSLayoutAttributeCenterX
                                                        multiplier:1.0f
                                                           constant:0.0f]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[emailSignin]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    
    NSMutableArray *mutableConstraints = [NSMutableArray array];
    [mutableConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-200-[reason]"
                                                                                    options:0
                                                                                    metrics:0
                                                                                      views:views]];
    [mutableConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[logo]-30-[face(==44)]-[g(==44)]-[emailSignup(==44)]-20-[skip(==30)]-20-[emailSignin(==44)]-0-|"
                                                                                    options:0
                                                                                    metrics:0
                                                                                      views:views]];
    constraintsForRegularClass = [NSArray arrayWithArray:mutableConstraints];
    [mutableConstraints removeAllObjects];
    
    [mutableConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-35-[logo]-30-[reason]"
                                                                                    options:0
                                                                                    metrics:0
                                                                                      views:views]];
    [mutableConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[face(==44)]-[g(==44)]-[emailSignup(==44)]-20-[skip(==30)]-20-[emailSignin(==44)]-0-|"
                                                                                    options:0
                                                                                    metrics:0
                                                                                      views:views]];
    constraintsForCompactClass = [NSArray arrayWithArray:mutableConstraints];

    if ([self respondsToSelector:@selector(traitCollection)]) {
        if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
            [self.view addConstraints:constraintsForRegularClass];
        } else {
            [self.view addConstraints:constraintsForCompactClass];
        }
    } else {
        [self.view addConstraints:constraintsForCompactClass];
    }
}

#pragma mark Orientation and Screen Resizing

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    // check to see if we've transitioned between regular and compact size classes
    if (self.traitCollection.horizontalSizeClass == previousTraitCollection.horizontalSizeClass)
        return;
    
    // iNat wordmark will change, both in size and placing
    int logoSize;
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        [self.view removeConstraints:constraintsForCompactClass];
        [self.view addConstraints:constraintsForRegularClass];
        logoSize = 200;
    } else {
        [self.view removeConstraints:constraintsForRegularClass];
        [self.view addConstraints:constraintsForCompactClass];
        logoSize = 160;
    }
    
    FAKINaturalist *inatWordmark = [FAKINaturalist inatWordmarkIconWithSize:logoSize];
    [inatWordmark addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
    self.logoLabel.attributedText = inatWordmark.attributedString;
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

#pragma mark - setters/getters

- (void)setSkippable:(BOOL)skippable {
    if (_skippable == skippable)
        return;
    
    _skippable = skippable;
    self.skipButton.hidden = !skippable;
}

- (BOOL)skippable {
    return _skippable;
}

- (void)setCancellable:(BOOL)cancellable {
    if (_cancellable == cancellable)
        return;
    
    _cancellable = cancellable;
    [self.navigationController setNavigationBarHidden:!cancellable animated:NO];
}

- (BOOL)cancellable {
    return _cancellable;
}

- (void)setReason:(NSString *)reason {
    if (_reason == reason)
        return;
    
    _reason = reason;
    self.reasonLabel.text = _reason;
    self.reasonLabel.hidden = (reason && reason.length > 0);
    if (self.reason && self.reason.length > 0) {
        self.reasonLabel.text = self.reason;
    } else {
        self.reasonLabel.hidden = YES;
    }

    [self.view setNeedsLayout];
}

- (NSString *)reason {
    return _reason;
}

@end
