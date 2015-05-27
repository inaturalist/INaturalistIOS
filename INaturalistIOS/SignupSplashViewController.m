//
//  SignupSplashViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/14/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonIcons.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <SVProgressHUD/SVProgressHUD.h>

#import "GPPSignIn.h"

#import "SignupSplashViewController.h"
#import "NSAttributedString+InatHelpers.h"
#import "INaturalistAppDelegate.h"
#import "LoginController.h"
#import "SignupViewController.h"
#import "GooglePlusAuthViewController.h"
#import "UIColor+INaturalist.h"
#import "SplitTextButton.h"
#import "FAKInaturalist.h"

@interface SignupSplashViewController () {
    UIImage *orangeFlower, *moth, *purpleFlower;
    NSTimer *backgroundCycleTimer;
    
    BOOL _skippable;
    BOOL _cancellable;
    NSString *_reason;
}
@end

@implementation SignupSplashViewController

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
    
    backgroundCycleTimer = [NSTimer bk_scheduledTimerWithTimeInterval:5.0f
                                                                block:^(NSTimer *timer) {
                                                                    UIImage *newImage;
                                                                    if (self.backgroundImageView.image == orangeFlower) {
                                                                        newImage = moth;
                                                                    } else if (self.backgroundImageView.image == moth) {
                                                                        newImage = purpleFlower;
                                                                    } else {
                                                                        newImage = orangeFlower;
                                                                    }
                                                                    [UIView transitionWithView:self.backgroundImageView
                                                                                      duration:0.5f
                                                                                       options:UIViewAnimationOptionTransitionCrossDissolve
                                                                                    animations:^{
                                                                                        self.backgroundImageView.image = newImage;
                                                                                    }
                                                                                    completion:NULL];
                                                                }
                                                              repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
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
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3f
                             animations:^{
                                 self.skipButton.alpha = 1.0f;
                             }];
        });
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
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] bk_initWithImage:closeImage
                                                                                 style:UIBarButtonItemStylePlain
                                                                               handler:^(id sender) {
                                                                                   [self dismissViewControllerAnimated:YES
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
        
        FAKINaturalist *logo = [FAKINaturalist inatWordmarkIconWithSize:160];
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
        label.font = [UIFont italicSystemFontOfSize:15.0f];
        label.textAlignment = NSTextAlignmentCenter;
        
        if (self.reason && self.reason.length > 0) {
            label.text = self.reason;
        } else {
            label.hidden = YES;
        }
        
        label;
    });
    [self.view addSubview:self.reasonLabel];
    
    self.loginFaceButton = ({
        SplitTextButton *button = [[SplitTextButton alloc] initWithFrame:CGRectZero];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        button.leftTitleLabel.attributedText = ({
            FAKIcon *face = [FAKIonIcons socialFacebookIconWithSize:25.0f];
            face.attributedString;
        });
        button.rightTitleLabel.attributedText = [NSAttributedString inat_attrStrWithBaseStr:NSLocalizedString(@"Log In with Facebook", "@base text for fb login button")
                                                                                  baseAttrs:@{ NSFontAttributeName: [UIFont systemFontOfSize:18.0f] }
                                                                                   emSubstr:NSLocalizedString(@"Facebook", @"portion of the base text for fb login button that is bold. must be a substring of the base test.")
                                                                                    emAttrs:@{ NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0f] }];
        
        [button bk_addEventHandler:^(id sender) {
            
            if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                            message:NSLocalizedString(@"Try again next time you're connected to the Internet.", nil)
                                           delegate:self
                                  cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                  otherButtonTitles:nil] show];
                return;
            }
            
            INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate.loginController loginWithFacebookSuccess:^(NSDictionary *info) {
                [self dismissViewControllerAnimated:YES completion:nil];
            } failure:^(NSError *error) {
                [SVProgressHUD showErrorWithStatus:error.localizedDescription];
            }];

        } forControlEvents:UIControlEventTouchUpInside];
        
        button;
    });
    [self.view addSubview:self.loginFaceButton];
    
    self.loginGButton = ({
        SplitTextButton *button = [[SplitTextButton alloc] initWithFrame:CGRectZero];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        button.leftTitleLabel.attributedText = ({
            FAKIcon *face = [FAKIonIcons socialGoogleplusIconWithSize:25.0f];
            face.attributedString;
        });
        button.rightTitleLabel.attributedText = [NSAttributedString inat_attrStrWithBaseStr:NSLocalizedString(@"Log In with Google+", "@base text for g+ login button")
                                                                                  baseAttrs:@{ NSFontAttributeName: [UIFont systemFontOfSize:18.0f] }
                                                                                   emSubstr:NSLocalizedString(@"Google+", @"portion of the base text for g+ login button that is bold. must be a substring of the base test.")
                                                                                    emAttrs:@{ NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0f] }];
        
        [button bk_addEventHandler:^(id sender) {
            
            if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                            message:NSLocalizedString(@"Try again next time you're connected to the Internet.", nil)
                                           delegate:self
                                  cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                  otherButtonTitles:nil] show];
                return;
            }
            
            INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];

            GooglePlusAuthViewController *vc = [GooglePlusAuthViewController controllerWithScope:appDelegate.loginController.scopesForGoogleSignin
                                                                                        clientID:appDelegate.loginController.clientIdForGoogleSignin
                                                                                    clientSecret:nil
                                                                                keychainItemName:nil
                                                                                        delegate:appDelegate.loginController
                                                                                finishedSelector:@selector(viewController:finishedAuth:error:)];
            [self.navigationController pushViewController:vc animated:YES];
            
            // inat green button tint
            [self.navigationController.navigationBar setTintColor:[UIColor inatTint]];
            
            // standard navigation bar
            [self.navigationController.navigationBar setBackgroundImage:nil
                                                          forBarMetrics:UIBarMetricsDefault];
            [self.navigationController.navigationBar setShadowImage:nil];
            [self.navigationController.navigationBar setTranslucent:YES];
            [self.navigationController setNavigationBarHidden:NO];
            
        } forControlEvents:UIControlEventTouchUpInside];

        button;
    });
    [self.view addSubview:self.loginGButton];
    
    self.signupEmailButton = ({
        SplitTextButton *button = [[SplitTextButton alloc] initWithFrame:CGRectZero];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        button.leftTitleLabel.attributedText = ({
            FAKIcon *face = [FAKIonIcons emailIconWithSize:25.0f];
            face.attributedString;
        });
        button.rightTitleLabel.attributedText = [NSAttributedString inat_attrStrWithBaseStr:NSLocalizedString(@"Sign Up with Email", "@base text for email signup button")
                                                                                  baseAttrs:@{ NSFontAttributeName: [UIFont systemFontOfSize:18.0f] }
                                                                                   emSubstr:NSLocalizedString(@"Email", @"portion of the base text for email signup button that is bold. must be a substring of the base test.")
                                                                                    emAttrs:@{ NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0f] }];
        
        [button bk_addEventHandler:^(id sender) {
            
            SignupViewController *signupVC = [[SignupViewController alloc] initWithNibName:nil bundle:nil];
            signupVC.backgroundImage = self.backgroundImageView.image;
            [self.navigationController pushViewController:signupVC animated:YES];
            
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
        button.layoutMargins = UIEdgeInsetsMake(50, 0, 50, 0);
        
        [button bk_addEventHandler:^(id sender) {
            if (self.skipAction) {
                self.skipAction();
            }
        } forControlEvents:UIControlEventTouchUpInside];
        
        button;
    });
    [self.view addSubview:self.skipButton];
    
    self.signinEmailButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        button.tintColor = [UIColor whiteColor];
        [button setAttributedTitle:[NSAttributedString inat_attrStrWithBaseStr:NSLocalizedString(@"Already have an account? Sign in", "@base text for email sign in button")
                                                                     baseAttrs:@{
                                                                                 NSFontAttributeName: [UIFont systemFontOfSize:14.0f],
                                                                                 NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent:0.5f],
                                                                                 }
                                                                      emSubstr:NSLocalizedString(@"Sign in", @"portion of the base text for email sign in button that is bold. must be a substring of the base test.")
                                                                       emAttrs:@{
                                                                                 NSFontAttributeName: [UIFont boldSystemFontOfSize:14.0f],
                                                                                 NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent:1.0f],
                                                                                 }]
                          forState:UIControlStateNormal];
        
        button.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1f];
        
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
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[face]-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[g]-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[emailSignup]-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
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


    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-35-[logo]-[reason]"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[face(==44)]-[g(==44)]-[emailSignup(==44)]-20-[skip(==30)]-20-[emailSignin(==44)]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.loginFaceButton
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:0.6f
                                                           constant:0.0f]];

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
