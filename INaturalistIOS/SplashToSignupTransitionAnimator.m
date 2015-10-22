//
//  SplashToSignupTransitionAnimator.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/26/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "SplashToSignupTransitionAnimator.h"
#import "SignupSplashViewController.h"
#import "SignupViewController.h"
#import "SplitTextButton.h"

@implementation SplashToSignupTransitionAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return .4f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController* toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    SignupViewController *signup = (SignupViewController *)toViewController;
    
    UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    SignupSplashViewController *splash = (SignupSplashViewController *)fromViewController;
    
    // insert the signup view underneath the splash view in the transition context
    [[transitionContext containerView] insertSubview:signup.view atIndex:0];
    
    // Custom transitions break topLayoutGuide in iOS 7, fix its constraint
    CGFloat navigationBarHeight = signup.navigationController.navigationBar.frame.size.height;
    for (NSLayoutConstraint *constraint in signup.view.constraints) {
        if (constraint.firstItem == signup.topLayoutGuide
            && constraint.firstAttribute == NSLayoutAttributeHeight
            && constraint.secondItem == nil
            && constraint.constant < navigationBarHeight) {
            constraint.constant += navigationBarHeight;
        }
    }
    
    // layout the container to get the constraints the toVC in iOS7
    [[transitionContext containerView] layoutIfNeeded];

    CGFloat width = splash.view.frame.size.width;
    
    // signup screen stuff starts off-screen to the right
    signup.signupTableView.frame = CGRectOffset(signup.signupTableView.frame, width, 0);
    signup.termsLabel.frame = CGRectOffset(signup.termsLabel.frame, width, 0);
    signup.navigationController.navigationBar.frame = CGRectOffset(signup.navigationController.navigationBar.frame, width, 0);
    
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
                         splash.logoImageView.frame = CGRectOffset(splash.logoImageView.frame, -width, 0);
                         splash.reasonLabel.frame = CGRectOffset(splash.reasonLabel.frame, -width, 0);
                         splash.loginFaceButton.frame = CGRectOffset(splash.loginFaceButton.frame, -width, 0);
                         splash.loginGButton.frame = CGRectOffset(splash.loginGButton.frame, -width, 0);
                         splash.signupEmailButton.frame = CGRectOffset(splash.signupEmailButton.frame, -width, 0);
                         splash.skipButton.frame = CGRectOffset(splash.skipButton.frame, -width, 0);
                         splash.signinEmailButton.frame = CGRectOffset(splash.signinEmailButton.frame, -width, 0);
                         
                         // migrate the signup screen stuff in from the right
                         signup.signupTableView.frame = CGRectOffset(signup.signupTableView.frame, -width, 0);
                         signup.termsLabel.frame = CGRectOffset(signup.termsLabel.frame, -width, 0);

                         signup.navigationController.navigationBar.frame = CGRectOffset(signup.navigationController.navigationBar.frame, -width, 0);

                     }
                     completion:^(BOOL finished) {
                         
                         [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
                         
                         // reset the splash screen
                         splash.blurView.alpha = 1.0f;
                         splash.backgroundImageView.alpha = 1.0f;
                         
                         splash.logoImageView.frame = CGRectOffset(splash.logoImageView.frame, width, 0);
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
