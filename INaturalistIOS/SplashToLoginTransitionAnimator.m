//
//  SplashToLoginTransitionAnimator.m
//  iNaturalist
//
//  Created by Alex Shepard on 6/2/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "SplashToLoginTransitionAnimator.h"

#import "SignupSplashViewController.h"
#import "LoginViewController.h"
#import "SplitTextButton.h"

@implementation SplashToLoginTransitionAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return .4f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController* toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    LoginViewController *login = (LoginViewController *)toViewController;
    
    UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    SignupSplashViewController *splash = (SignupSplashViewController *)fromViewController;
    
    // insert the login view underneath the list view in the transition context
    [[transitionContext containerView] insertSubview:login.view atIndex:0];
    
    // Custom transitions break topLayoutGuide in iOS 7, fix its constraint
    CGFloat navigationBarHeight = login.navigationController.navigationBar.frame.size.height;
    for (NSLayoutConstraint *constraint in login.view.constraints) {
        if (constraint.firstItem == login.topLayoutGuide
            && constraint.firstAttribute == NSLayoutAttributeHeight
            && constraint.secondItem == nil
            && constraint.constant < navigationBarHeight) {
            constraint.constant += navigationBarHeight;
        }
    }
    
    // layout the container to get the constraints the toVC in iOS7
    [[transitionContext containerView] layoutIfNeeded];
    
    CGFloat width = splash.view.frame.size.width;
    
    // login screen stuff starts off-screen to the right
    login.loginTableView.frame = CGRectOffset(login.loginTableView.frame, width, 0);
    login.gButton.frame = CGRectOffset(login.gButton.frame, width, 0);
    login.faceButton.frame = CGRectOffset(login.faceButton.frame, width, 0);
    login.orLabel.frame = CGRectOffset(login.orLabel.frame, width, 0);
    login.navigationController.navigationBar.frame = CGRectOffset(login.navigationController.navigationBar.frame, width, 0);
    
    if (splash.blurView) {
        // hide the splash background to show the underlying content
        splash.blurView.alpha = 0.0f;
        splash.backgroundImageView.alpha = 0.0f;
    }
    
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                     animations:^{
                         
                         if (!splash.blurView) {
                             // animate the non-blurred image to zero, effectively animating in the blur
                             splash.backgroundImageView.alpha = 0.0f;
                         }
                         
                         // migrate all the splash screen stuff off to the left
                         splash.logoLabel.frame = CGRectOffset(splash.logoLabel.frame, -width, 0);
                         splash.reasonLabel.frame = CGRectOffset(splash.reasonLabel.frame, -width, 0);
                         splash.loginFaceButton.frame = CGRectOffset(splash.loginFaceButton.frame, -width, 0);
                         splash.loginGButton.frame = CGRectOffset(splash.loginGButton.frame, -width, 0);
                         splash.signupEmailButton.frame = CGRectOffset(splash.signupEmailButton.frame, -width, 0);
                         splash.skipButton.frame = CGRectOffset(splash.skipButton.frame, -width, 0);
                         splash.signinEmailButton.frame = CGRectOffset(splash.signinEmailButton.frame, -width, 0);
                         
                         // migrate the login screen stuff in from the right
                         login.loginTableView.frame = CGRectOffset(login.loginTableView.frame, -width, 0);
                         login.gButton.frame = CGRectOffset(login.gButton.frame, -width, 0);
                         login.faceButton.frame = CGRectOffset(login.faceButton.frame, -width, 0);
                         login.orLabel.frame = CGRectOffset(login.orLabel.frame, -width, 0);
                         
                         login.navigationController.navigationBar.frame = CGRectOffset(login.navigationController.navigationBar.frame, -width, 0);
                         
                     }
                     completion:^(BOOL finished) {
                         
                         [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
                         
                         // reset the splash screen
                         splash.blurView.alpha = 1.0f;
                         splash.backgroundImageView.alpha = 1.0f;
                         
                         splash.logoLabel.frame = CGRectOffset(splash.logoLabel.frame, width, 0);
                         splash.reasonLabel.frame = CGRectOffset(splash.reasonLabel.frame, width, 0);
                         splash.loginFaceButton.frame = CGRectOffset(splash.loginFaceButton.frame, width, 0);
                         splash.loginGButton.frame = CGRectOffset(splash.loginGButton.frame, width, 0);
                         splash.signupEmailButton.frame = CGRectOffset(splash.signupEmailButton.frame, width, 0);
                         splash.skipButton.frame = CGRectOffset(splash.skipButton.frame, width, 0);
                         splash.signinEmailButton.frame = CGRectOffset(splash.signinEmailButton.frame, width, 0);
                         splash.signinEmailButton.frame = CGRectOffset(splash.signinEmailButton.frame, width, 0);
                         
                     }];
    
}

@end
