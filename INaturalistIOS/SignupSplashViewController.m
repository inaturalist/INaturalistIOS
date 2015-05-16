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

@interface SignupSplashViewController () {
    UIImageView *backgroundImageView;
    
    UIButton *loginFaceButton;
    UIButton *loginGButton;
    UIButton *signupEmailButton;
    UIButton *skipButton;
    
    UIButton *signinEmailButton;
        
    BOOL _skippable;
    BOOL _cancellable;
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
    
    // completely clear background
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    [self.navigationController.navigationBar setTranslucent:YES];
    
    if (self.animateIn) {
        loginFaceButton.alpha = 0.0f;
        loginGButton.alpha = 0.0f;
        skipButton.alpha = 0.0f;
        signinEmailButton.alpha = 0.0f;
        signupEmailButton.alpha = 0.0f;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.animateIn) {
        // only do this once
        self.animateIn = NO;
        
        [UIView animateWithDuration:0.3f
                         animations:^{
                             loginFaceButton.alpha = 1.0f;
                             loginGButton.alpha = 1.0f;
                             signupEmailButton.alpha = 1.0f;
                             signinEmailButton.alpha = 1.0f;
                         }];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3f
                             animations:^{
                                 skipButton.alpha = 1.0f;
                             }];
        });
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] bk_initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                             handler:^(id sender) {
                                                                                                 [self dismissViewControllerAnimated:YES
                                                                                                                          completion:nil];
                                                                                             }];
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor whiteColor];
    
    backgroundImageView = ({
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
        iv.translatesAutoresizingMaskIntoConstraints = NO;
        
        iv.contentMode = UIViewContentModeScaleAspectFill;
        iv.image = [UIImage imageNamed:@"signup_iphone6_test_01.jpg"];
        
        iv;
    });
    [self.view addSubview:backgroundImageView];
    
    
    loginFaceButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.translatesAutoresizingMaskIntoConstraints = NO;

        button.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.4f];
        button.tintColor = [UIColor whiteColor];
        button.layer.cornerRadius = 2.0f;

        [button setAttributedTitle:[NSAttributedString inat_attrStrWithBaseStr:NSLocalizedString(@"Log In with Facebook", "@base text for fb login button")
                                                                     baseAttrs:@{ NSFontAttributeName: [UIFont systemFontOfSize:18.0f] }
                                                                      emSubstr:NSLocalizedString(@"Facebook", @"portion of the base text for fb login button that is bold. must be a substring of the base test.")
                                                                       emAttrs:@{ NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0f] }]
                          forState:UIControlStateNormal];
        
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
    [self.view addSubview:loginFaceButton];
    
    loginGButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        button.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.4f];
        button.tintColor = [UIColor whiteColor];
        button.layer.cornerRadius = 2.0f;

        [button setAttributedTitle:[NSAttributedString inat_attrStrWithBaseStr:NSLocalizedString(@"Log In with Google+", "@base text for g+ login button")
                                                                     baseAttrs:@{ NSFontAttributeName: [UIFont systemFontOfSize:18.0f] }
                                                                      emSubstr:NSLocalizedString(@"Google+", @"portion of the base text for g+ login button that is bold. must be a substring of the base test.")
                                                                       emAttrs:@{ NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0f] }]
                          forState:UIControlStateNormal];
        
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
    [self.view addSubview:loginGButton];
    
    signupEmailButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        button.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.4f];
        button.tintColor = [UIColor whiteColor];
        button.layer.cornerRadius = 2.0f;
        [button setAttributedTitle:[NSAttributedString inat_attrStrWithBaseStr:NSLocalizedString(@"Sign Up with Email", "@base text for email signup button")
                                                                     baseAttrs:@{ NSFontAttributeName: [UIFont systemFontOfSize:18.0f] }
                                                                      emSubstr:NSLocalizedString(@"Email", @"portion of the base text for email signup button that is bold. must be a substring of the base test.")
                                                                       emAttrs:@{ NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0f] }]
                          forState:UIControlStateNormal];
        
        [button bk_addEventHandler:^(id sender) {
            
            SignupViewController *signupVC = [[SignupViewController alloc] initWithNibName:nil bundle:nil];
            [self.navigationController pushViewController:signupVC animated:YES];
            
        } forControlEvents:UIControlEventTouchUpInside];
        
        button;
    });
    [self.view addSubview:signupEmailButton];
    
    skipButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        button.tintColor = [UIColor whiteColor];
        [button setTitle:NSLocalizedString(@"Skip for Now >", @"title for skip for now button during signup prompt")
                forState:UIControlStateNormal];
        
        button.hidden = !self.skippable;
        
        [button bk_addEventHandler:^(id sender) {
            if (self.skipAction) {
                self.skipAction();
            }
        } forControlEvents:UIControlEventTouchUpInside];
        
        button;
    });
    [self.view addSubview:skipButton];
    
    signinEmailButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        button.tintColor = [UIColor whiteColor];
        [button setAttributedTitle:[NSAttributedString inat_attrStrWithBaseStr:NSLocalizedString(@"Already have an account? Sign in", "@base text for email sign in button")
                                                                     baseAttrs:@{ NSFontAttributeName: [UIFont systemFontOfSize:14.0f] }
                                                                      emSubstr:NSLocalizedString(@"Sign in", @"portion of the base text for email sign in button that is bold. must be a substring of the base test.")
                                                                       emAttrs:@{ NSFontAttributeName: [UIFont boldSystemFontOfSize:14.0f] }]
                          forState:UIControlStateNormal];
        
        button;
    });
    [self.view addSubview:signinEmailButton];
    
    NSDictionary *views = @{
                            @"bg": backgroundImageView,
                            @"face": loginFaceButton,
                            @"g": loginGButton,
                            @"emailSignup": signupEmailButton,
                            @"skip": skipButton,
                            @"emailSignin": signinEmailButton,
                            };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[bg]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[bg]-0-|"
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
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[skip]-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[emailSignin]-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];


    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[face]-[g]-[emailSignup]-[skip]"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[emailSignin]-20-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:loginFaceButton
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
    skipButton.hidden = !skippable;
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

@end
