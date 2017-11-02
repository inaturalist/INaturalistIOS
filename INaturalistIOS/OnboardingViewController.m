//
//  OnboardingViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 8/28/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "OnboardingViewController.h"

@interface OnboardingViewController ()
@property IBOutlet UIPageControl *pageControl;
@property (assign) OnboardingPageViewController *onboardingPageViewController;
@end

@implementation OnboardingViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.pageControl addTarget:self action:@selector(pageControlChangedIndex:) forControlEvents:UIControlEventValueChanged];
    [self.pageControl setTransform:CGAffineTransformMakeScale(1.2, 1.2)];
    

    UIPageControl *pageControl = [UIPageControl appearanceWhenContainedInInstancesOfClasses:@[ [OnboardingViewController class] ]];
    pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    pageControl.currentPageIndicatorTintColor = [UIColor blackColor];
    pageControl.tintColor = [UIColor blackColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

- (BOOL)shouldAutorotate {
    return ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue destinationViewController] isKindOfClass:[OnboardingPageViewController class]]) {
        OnboardingPageViewController *pvc = (OnboardingPageViewController *)[segue destinationViewController];
        pvc.onboardingDelegate = self;
        self.onboardingPageViewController = pvc;
    }
}

- (void)onboardingPageViewController:(OnboardingPageViewController *)vc didUpdatePageCount:(NSInteger)count {
    self.pageControl.numberOfPages = count;
}

- (void)onboardingPageViewController:(OnboardingPageViewController *)bc didUpdatePageIndex:(NSInteger)index {
    self.pageControl.currentPage = index;
    if (index == self.pageControl.numberOfPages - 1) {
        // hide the page control
        self.pageControl.alpha = 0.0f;
    } else {
        self.pageControl.alpha = 1.0f;
    }
}

- (void)onboardingPageViewController:(OnboardingPageViewController *)bc willUpdateToPageIndex:(NSInteger)newIndex fromPageIndex:(NSInteger)oldIndex {
    NSInteger last = self.pageControl.numberOfPages - 1;
    if (newIndex == last || oldIndex == last) {
        self.pageControl.alpha = 0.0f;
    } else {
        self.pageControl.alpha = 1.0f;
    }
}

- (void)pageControlChangedIndex:(UIPageControl *)pageControl {
    [self.onboardingPageViewController scrollToViewControllerAtIndex:pageControl.currentPage];

}

@end
