//
//  ConfirmPhotoToEditObsTransitionAnimator.m
//  iNaturalist
//
//  Created by Alex Shepard on 12/8/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <VICMAImageView/VICMAImageView.h>

#import "ConfirmPhotoToEditObsTransitionAnimator.h"
#import "ConfirmPhotoViewController.h"
#import "ObsEditV2ViewController.h"
#import "MultiImageView.h"
#import "PhotoScrollViewCell.h"
#import "PhotoChicletCell.h"

@implementation ConfirmPhotoToEditObsTransitionAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.6f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController* toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    ObsEditV2ViewController *edit = (ObsEditV2ViewController *)toViewController;
    
    UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    ConfirmPhotoViewController *confirmPhoto = (ConfirmPhotoViewController *)fromViewController;
    
    // insert the edit view underneath the confirm photo view in the transition context
    [[transitionContext containerView] insertSubview:edit.view atIndex:0];

    // Custom transitions break topLayoutGuide in iOS 7, fix its constraint
    CGFloat navigationBarHeight = confirmPhoto.navigationController.navigationBar.frame.size.height;
    for (NSLayoutConstraint *constraint in confirmPhoto.view.constraints) {
        if (constraint.firstItem == confirmPhoto.topLayoutGuide
            && constraint.firstAttribute == NSLayoutAttributeHeight
            && constraint.secondItem == nil
            && constraint.constant < navigationBarHeight) {
            constraint.constant += navigationBarHeight;
        }
    }
    
    // layout the container to get the constraints the toVC in iOS7
    [[transitionContext containerView] layoutIfNeeded];
    
    NSMutableArray *vivs = [NSMutableArray array];
    
    for (int i = 0; i < confirmPhoto.assets.count; i++) {
        UIImageView *iv = confirmPhoto.multiImageView.imageViews[i];
        // using VICMAImageView because we may need to animate changing the content mode
        VICMAImageView *viv = [[VICMAImageView alloc] initWithFrame:iv.frame];
        viv.layer.borderColor = iv.layer.borderColor;
        viv.layer.borderWidth = iv.layer.borderWidth;
        if (confirmPhoto.assets.count == 1) {
            viv.contentMode = UIViewContentModeScaleAspectFit;
        } else {
            viv.contentMode = UIViewContentModeScaleAspectFill;
        }
        viv.clipsToBounds = YES;
        viv.image = iv.image;
        [confirmPhoto.view addSubview:viv];
        
        [vivs addObject:viv];
    }
    
    NSMutableArray *chiclets = [NSMutableArray array];
    NSIndexPath *photoScrollViewIP = [NSIndexPath indexPathForItem:0 inSection:0];
    PhotoScrollViewCell *tvCell = [edit.tableView cellForRowAtIndexPath:photoScrollViewIP];
    for (int i = 0; i < confirmPhoto.assets.count; i++) {
        // i+1 to make room for the + chiclet
        NSIndexPath *chicletIndexPath = [NSIndexPath indexPathForItem:i+1 inSection:0];
        PhotoChicletCell *chicletCell = (PhotoChicletCell *)[tvCell.collectionView cellForItemAtIndexPath:chicletIndexPath];
        if (chicletCell) {
            [chiclets addObject:chicletCell];
            chicletCell.alpha = 0.0f;
        }
    }
    
    [transitionContext containerView].backgroundColor =  [UIColor whiteColor];
    confirmPhoto.multiImageView.backgroundColor = [UIColor blackColor];
    
    // delay showing the navbar until after this first animation finishes
    [edit.navigationController setNavigationBarHidden:YES animated:NO];
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] * 0.2f
                     animations:^{
                         confirmPhoto.multiImageView.backgroundColor = [UIColor whiteColor];
                     } completion:^(BOOL finished) {
                         // now start showing the navbar
                         [edit.navigationController setNavigationBarHidden:NO animated:YES];

                         // vivs are what will animate in place of miv
                         confirmPhoto.multiImageView.alpha = 0.0f;
                         
                         // edit screen starts off to the right
                         edit.view.center = CGPointMake(edit.view.center.x + edit.view.frame.size.width, edit.view.center.y);

                         [UIView animateWithDuration:[self transitionDuration:transitionContext] * .8f
                                          animations:^{
                                              // edit screen slides in from the right
                                              edit.view.center = CGPointMake(edit.view.center.x - edit.view.frame.size.width, edit.view.center.y);
                                              
                                              // vivs animate in to where chiclets are
                                              for (int i = 0; i < confirmPhoto.assets.count; i++) {
                                                  VICMAImageView *viv = vivs[i];
                                                  viv.layer.borderColor = [UIColor clearColor].CGColor;
                                                  viv.layer.borderWidth = 0.0f;

                                                  if (chiclets.count > i) {
                                                      PhotoChicletCell *chiclet = chiclets[i];
                                                      CGRect toFrame = [edit.view convertRect:chiclet.photoImageView.frame fromView:chiclet];
                                                      viv.frame = toFrame;
                                                      if (viv.contentMode != UIViewContentModeScaleAspectFill) {
                                                          viv.contentMode = UIViewContentModeScaleAspectFill;
                                                      }
                                                  } else {
                                                      // unless the chiclet is offscreen, in which case the viv just fades
                                                      // this isn't ideal, but...
                                                      viv.alpha = 0.0f;
                                                  }
                                              }
                                          } completion:^(BOOL finished) {
                                              // we can replace the animating vivs with the functional chiclets now
                                              for (PhotoChicletCell *chiclet in chiclets) {
                                                  chiclet.alpha = 1.0f;
                                              }

                                              for (VICMAImageView *viv in vivs) {
                                                  [viv removeFromSuperview];
                                              }

                                              // animation finished
                                              [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
                                          }];
                     }];
    
}


@end
