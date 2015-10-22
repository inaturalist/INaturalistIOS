//
//  LoginToSplashTransitionAnimator.m
//  iNaturalist
//
//  Created by Alex Shepard on 6/2/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "LoginToSplashTransitionAnimator.h"
#import "SignupSplashViewController.h"
#import "LoginViewController.h"
#import "SplitTextButton.h"

@implementation LoginToSplashTransitionAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return .4f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController* toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    SignupSplashViewController *splash = (SignupSplashViewController *)toViewController;
    
    UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    LoginViewController *login = (LoginViewController *)fromViewController;
    
    
    CGFloat width = login.view.frame.size.width;
    
    if (splash.blurView) {
        // hide the splash blurview until animation is complete
        splash.blurView.alpha = 0.0f;
    }
    // splash screen backgrond starts invisible
    splash.backgroundImageView.alpha = 0.0f;
    splash.backgroundImageView.image = login.backgroundImage;
    
    // splash screen UI elements start off-screen to the left
    splash.logoImageView.frame = CGRectOffset(splash.logoImageView.frame, -width, 0);
    splash.reasonLabel.frame = CGRectOffset(splash.reasonLabel.frame, -width, 0);
    splash.loginFaceButton.frame = CGRectOffset(splash.loginFaceButton.frame, -width, 0);
    splash.loginGButton.frame = CGRectOffset(splash.loginGButton.frame, -width, 0);
    splash.signupEmailButton.frame = CGRectOffset(splash.signupEmailButton.frame, -width, 0);
    splash.skipButton.frame = CGRectOffset(splash.skipButton.frame, -width, 0);
    splash.signinEmailButton.frame = CGRectOffset(splash.signinEmailButton.frame, -width, 0);
    
    // insert the splash view above the login view in the transition context
    [[transitionContext containerView] insertSubview:splash.view atIndex:1];
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                     animations:^{
                         
                         if (!splash.blurView) {
                             // animate the non-blurred image to 1, effectively animating out the blur
                             splash.backgroundImageView.alpha = 1.0f;
                         }
                         
                         // migrate all the splash screen stuff in from the right
                         splash.logoImageView.frame = CGRectOffset(splash.logoImageView.frame, width, 0);
                         splash.reasonLabel.frame = CGRectOffset(splash.reasonLabel.frame, width, 0);
                         splash.loginFaceButton.frame = CGRectOffset(splash.loginFaceButton.frame, width, 0);
                         splash.loginGButton.frame = CGRectOffset(splash.loginGButton.frame, width, 0);
                         splash.signupEmailButton.frame = CGRectOffset(splash.signupEmailButton.frame, width, 0);
                         splash.skipButton.frame = CGRectOffset(splash.skipButton.frame, width, 0);
                         splash.signinEmailButton.frame = CGRectOffset(splash.signinEmailButton.frame, width, 0);
                         
                         // migrate the signup screen stuff off from the right
                         login.loginTableView.frame = CGRectOffset(login.loginTableView.frame, width, 0);
                         login.gButton.frame = CGRectOffset(login.gButton.frame, width, 0);
                         login.faceButton.frame = CGRectOffset(login.faceButton.frame, width, 0);
                         login.orLabel.frame = CGRectOffset(login.orLabel.frame, width, 0);

                         
                         if (!splash.cancellable)
                             login.navigationController.navigationBar.frame = CGRectOffset(login.navigationController.navigationBar.frame, width, 0);
                         
                     }
                     completion:^(BOOL finished) {
                         
                         if (splash.blurView) {
                             splash.backgroundImageView.alpha = 1.0f;
                             splash.blurView.alpha = 1.0f;
                         }
                         
                         [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
                         
                         // reset the signup screen
                         login.loginTableView.frame = CGRectOffset(login.loginTableView.frame, -width, 0);
                         login.gButton.frame = CGRectOffset(login.gButton.frame, -width, 0);
                         login.faceButton.frame = CGRectOffset(login.faceButton.frame, -width, 0);
                         login.orLabel.frame = CGRectOffset(login.orLabel.frame, -width, 0);

                         if (!splash.cancellable)
                             login.navigationController.navigationBar.frame = CGRectOffset(login.navigationController.navigationBar.frame, -width, 0);
                         
                     }];
    
}

@end
