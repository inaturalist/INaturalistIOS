//
//  INaturalistAppDelegate+TransitionAnimators.m
//  iNaturalist
//
//  Created by Alex Shepard on 6/2/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "INaturalistAppDelegate+TransitionAnimators.h"

#import "SignupSplashViewController.h"
#import "SignupViewController.h"
#import "LoginViewController.h"

#import "SplashToSignupTransitionAnimator.h"
#import "SignupToSplashTransitionAnimator.h"
#import "SplashToLoginTransitionAnimator.h"
#import "LoginToSplashTransitionAnimator.h"

@implementation INaturalistAppDelegate (TransitionAnimators)

#pragma mark - Animator Transitions / Sizzle

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController *)fromVC
                                                 toViewController:(UIViewController *)toVC {
    
    
    if ([fromVC isKindOfClass:[SignupSplashViewController class]] && [toVC isKindOfClass:[SignupViewController class]])
        return [[SplashToSignupTransitionAnimator alloc] init];
    if ([fromVC isKindOfClass:[SignupViewController class]] && [toVC isKindOfClass:[SignupSplashViewController class]])
        return [[SignupToSplashTransitionAnimator alloc] init];
    
    if ([fromVC isKindOfClass:[SignupSplashViewController class]] && [toVC isKindOfClass:[LoginViewController class]])
        return [[SplashToLoginTransitionAnimator alloc] init];
    if ([fromVC isKindOfClass:[LoginViewController class]] && [toVC isKindOfClass:[SignupSplashViewController class]])
        return [[LoginToSplashTransitionAnimator alloc] init];
    
    return nil;
}

@end
