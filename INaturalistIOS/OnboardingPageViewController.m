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

    UIPageControl *pageControl = [UIPageControl appearanceWhenContainedIn:[OnboardingPageViewController class], nil];
    pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    pageControl.currentPageIndicatorTintColor = [UIColor blackColor];
    pageControl.tintColor = [UIColor blackColor];
    
    NSArray *identifiers = @[@"onboarding-logo",
                             @"onboarding-observe",
                             @"onboarding-share",
                             @"onboarding-learn",
                             @"onboarding-contribute",
                             @"onboarding-login"];
    
    UIStoryboard *onboarding = [UIStoryboard storyboardWithName:@"Onboarding"
                                                         bundle:[NSBundle mainBundle]];
    self.orderedViewControllers = [identifiers bk_map:^id(NSString *identifier) {
        return [onboarding instantiateViewControllerWithIdentifier:identifier];
    }];
    
    [self setViewControllers:@[ [self.orderedViewControllers firstObject] ]
                   direction:UIPageViewControllerNavigationDirectionForward
                    animated:YES
                  completion:nil];
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

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    return self.orderedViewControllers.count;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    UIViewController *first = [self.orderedViewControllers firstObject];
    NSInteger firstViewControllerIndex = [self.orderedViewControllers indexOfObject:first];
    if (firstViewControllerIndex == NSNotFound) {
        return 0;
    }
    return firstViewControllerIndex;
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray<UIViewController *> *)pendingViewControllers {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *subviews = self.view.subviews;
        for (int i=0; i<[subviews count]; i++) {
            if ([[subviews objectAtIndex:i] isKindOfClass:[UIPageControl class]]) {
                self.pageControl = (UIPageControl *)[subviews objectAtIndex:i];
                self.pageControl.hidden = YES;
            }
        }
    });
    
    UIViewController *login = [self.orderedViewControllers lastObject];
    
    // hide the page control on the login (last) screen
    if ([pendingViewControllers containsObject:login]) {
        self.pageControl.hidden = YES;
    } else {
        self.pageControl.hidden = NO;
    }
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
    
    UIViewController *login = [self.orderedViewControllers lastObject];
    
    if ([previousViewControllers containsObject:login] && !completed) {
        // started to transition away from login, but backed out
        // page control should be hidden on login
        self.pageControl.hidden = YES;
    }
    
    if (![previousViewControllers containsObject:login] && !completed) {
        // started to transition away from anything other than login, but backed out
        // page control should be visible
        self.pageControl.hidden = NO;
    }
}



@end
