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
#import "ConfirmPhotoViewController.h"
#import "ObsEditV2ViewController.h"

#import "SplashToSignupTransitionAnimator.h"
#import "SignupToSplashTransitionAnimator.h"
#import "SplashToLoginTransitionAnimator.h"
#import "LoginToSplashTransitionAnimator.h"
#import "ConfirmPhotoToEditObsTransitionAnimator.h"

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
    
    if ([fromVC isKindOfClass:[ConfirmPhotoViewController class]] && [toVC isKindOfClass:[ObsEditV2ViewController class]])
        return [[ConfirmPhotoToEditObsTransitionAnimator alloc] init];

    
    return nil;
}


#pragma mark - Other NavControllerDelegate stuff
- (NSUInteger)navigationControllerSupportedInterfaceOrientations:(UINavigationController *)navigationController {

    UIViewController *rootVC = navigationController.viewControllers.firstObject;
    // signup & login are locked to portrait on iPhone
    if ([rootVC isKindOfClass:[SignupSplashViewController class]] || [rootVC isKindOfClass:[LoginViewController class]]) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            return UIInterfaceOrientationMaskPortrait;
        }
    }
    
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

@end
