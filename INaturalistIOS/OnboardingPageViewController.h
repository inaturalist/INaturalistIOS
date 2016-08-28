//
//  OnboardingPageViewController.h
//  iNaturalist
//
//  Created by Alex Shepard on 8/4/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OnboardingPageViewController;

@protocol OnboardingPageViewControllerDelegate
- (void)onboardingPageViewController:(OnboardingPageViewController *)vc didUpdatePageCount:(NSInteger)count;
- (void)onboardingPageViewController:(OnboardingPageViewController *)bc didUpdatePageIndex:(NSInteger)index;
- (void)onboardingPageViewController:(OnboardingPageViewController *)bc willUpdateToPageIndex:(NSInteger)newIndex fromPageIndex:(NSInteger)oldIndex;
@end

@interface OnboardingPageViewController : UIPageViewController
@property (assign) id <OnboardingPageViewControllerDelegate> onboardingDelegate;
- (void)scrollToViewControllerAtIndex:(NSInteger)index;
@end

