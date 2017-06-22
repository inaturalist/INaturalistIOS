//
//  OnboardingPageViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 8/4/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <BlocksKit/BlocksKit.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "OnboardingPageViewController.h"
#import "OnboardingLoginViewController.h"
#import "INaturalistAppDelegate.h"
#import "Analytics.h"

@interface OnboardingPageViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>
@property NSArray *orderedViewControllers;
@property UIPageControl *pageControl;
@end

@implementation OnboardingPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dataSource = self;
    self.delegate = self;
    
    self.view.backgroundColor = [UIColor colorWithHexString:@"#efefef"];

    
    NSArray *identifiers = @[@"onboarding-logo",
                             @"onboarding-observe",
                             @"onboarding-identify",
                             @"onboarding-discuss",
                             @"onboarding-contribute",
                             @"onboarding-login"];
    
    UIStoryboard *onboarding = [UIStoryboard storyboardWithName:@"Onboarding"
                                                         bundle:[NSBundle mainBundle]];
    self.orderedViewControllers = [identifiers bk_map:^id(NSString *identifier) {
        if ([identifier isEqualToString:@"onboarding-login"]) {
            OnboardingLoginViewController *vc = [onboarding instantiateViewControllerWithIdentifier:identifier];
            vc.skippable = YES;
            vc.skipAction = ^{
                [((INaturalistAppDelegate *)[UIApplication sharedApplication].delegate) showMainUI];
            };
            return vc;
        } else {
            return [onboarding instantiateViewControllerWithIdentifier:identifier];
        }
    }];
    
    [[Analytics sharedClient] event:kAnalyticsEventNavigateOnboardingScreenLogo];
    
    [self setViewControllers:@[ [self.orderedViewControllers firstObject] ]
                   direction:UIPageViewControllerNavigationDirectionForward
                    animated:YES
                  completion:nil];
    
    [self.onboardingDelegate onboardingPageViewController:self
                                       didUpdatePageCount:self.orderedViewControllers.count];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - page view controller helpers

- (UIViewController *)newViewControllerWithIdentifier:(NSString *)identifier {
    UIStoryboard *onboarding = [UIStoryboard storyboardWithName:@"Onboarding"
                                                         bundle:[NSBundle mainBundle]];
    return [onboarding instantiateViewControllerWithIdentifier:identifier];
}

#pragma mark - UIPageViewControllerDataSource


- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
    NSInteger viewControllerIndex = [self.orderedViewControllers indexOfObject:viewController];
    if (viewControllerIndex == NSNotFound) {
        return nil;
    }
    
    NSInteger previousIndex = viewControllerIndex - 1;
    
    // can't index below zero
    if (previousIndex < 0) {
        return nil;
    }
    
    // can't index above the count
    if (self.orderedViewControllers.count <= previousIndex) {
        return nil;
    }
    
    return self.orderedViewControllers[previousIndex];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    NSInteger viewControllerIndex = [self.orderedViewControllers indexOfObject:viewController];
    if (viewControllerIndex == NSNotFound) {
        return nil;
    }
    
    NSInteger nextIndex = viewControllerIndex + 1;
    
    // can't index below zero
    if (nextIndex < 0) {
        return nil;
    }
    
    // can't index above the count
    if (self.orderedViewControllers.count <= nextIndex) {
        return nil;
    }
    
    return self.orderedViewControllers[nextIndex];
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray<UIViewController *> *)pendingViewControllers {
    UIViewController *first = [self.viewControllers firstObject];
    NSInteger oldIndex = [self.orderedViewControllers indexOfObject:first];
    
    UIViewController *pending = [pendingViewControllers firstObject];
    NSInteger newIndex = [self.orderedViewControllers indexOfObject:pending];
    [[Analytics sharedClient] event:[self analyticsEventForIndex:newIndex]
                     withProperties:@{ @"via": @"onboarding" }];

    [self.onboardingDelegate onboardingPageViewController:self willUpdateToPageIndex:newIndex fromPageIndex:oldIndex];
}


- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
    
    UIViewController *first = [self.viewControllers firstObject];
    NSInteger index = [self.orderedViewControllers indexOfObject:first];
    [self.onboardingDelegate onboardingPageViewController:self didUpdatePageIndex:index];
}

- (void)scrollToViewControllerAtIndex:(NSInteger)newIndex {
    [[Analytics sharedClient] event:[self analyticsEventForIndex:newIndex]
                     withProperties:@{ @"via": @"onboarding" }];
    
    UIViewController *first = [self.viewControllers firstObject];
    NSInteger currentIndex = [self.orderedViewControllers indexOfObject:first];
    UIPageViewControllerNavigationDirection direction = newIndex >= currentIndex ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;
    UIViewController *nextViewController = [self.orderedViewControllers objectAtIndex:newIndex];
    [self scrollToViewController:nextViewController direction:direction];
}

- (void)scrollToViewController:(UIViewController *)vc direction:(UIPageViewControllerNavigationDirection)direction {
    __weak typeof(self)weakSelf = self;
    [self setViewControllers:@[vc]
                   direction:direction
                    animated:YES
                  completion:^(BOOL finished) {
                      // Setting the view controller programmatically does not fire
                      // any delegate methods, so we have to manually notify the
                      // 'onboardingDelegate' of the new index.
                      [weakSelf notifyOnboardingDelegateOfNewIndex];
                  }];
}

- (void)notifyOnboardingDelegateOfNewIndex {
    UIViewController *first = [self.viewControllers firstObject];
    NSInteger index = [self.orderedViewControllers indexOfObject:first];
    [self.onboardingDelegate onboardingPageViewController:self didUpdatePageIndex:index];
}

- (NSString *)analyticsEventForIndex:(NSInteger)index {
    return @[
             kAnalyticsEventNavigateOnboardingScreenLogo,
             kAnalyticsEventNavigateOnboardingScreenObserve,
             kAnalyticsEventNavigateOnboardingScreenShare,
             kAnalyticsEventNavigateOnboardingScreenLearn,
             kAnalyticsEventNavigateOnboardingScreenContribue,
             kAnalyticsEventNavigateOnboardingScreenLogin][index];
}

@end
