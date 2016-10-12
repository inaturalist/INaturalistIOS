//
//  INaturalistAppDelegate+TransitionAnimators.m
//  iNaturalist
//
//  Created by Alex Shepard on 6/2/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "INaturalistAppDelegate+TransitionAnimators.h"

#import "ConfirmPhotoViewController.h"
#import "ObsEditV2ViewController.h"

#import "ConfirmPhotoToEditObsTransitionAnimator.h"

@implementation INaturalistAppDelegate (TransitionAnimators)

#pragma mark - Animator Transitions / Sizzle

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController *)fromVC
                                                 toViewController:(UIViewController *)toVC {
    
    if ([fromVC isKindOfClass:[ConfirmPhotoViewController class]] && [toVC isKindOfClass:[ObsEditV2ViewController class]])
        return [[ConfirmPhotoToEditObsTransitionAnimator alloc] init];

    
    return nil;
}

@end
