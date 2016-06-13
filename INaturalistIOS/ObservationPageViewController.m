//
//  ObservationPageViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 11/27/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import "ObservationPageViewController.h"
#import "ObservationDetailViewController.h"

@implementation ObservationPageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.dataSource = self;
    self.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:animated];
}

#pragma mark - UIPageViewControllerDataSource
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    ObservationDetailViewController *vc = (ObservationDetailViewController *)viewController;
    Observation *currentObservation = vc.observation;
    Observation *nextObservation = [currentObservation nextObservation];
    if (nextObservation) {
        ObservationDetailViewController *nvc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"ObservationDetailViewController"];
        nvc.observation = nextObservation;
        nvc.delegate = vc.delegate;
        [vc save];
        return nvc;
    }
    return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    ObservationDetailViewController *vc = (ObservationDetailViewController *)viewController;
    Observation *currentObservation = vc.observation;
    Observation *prevObservation = [currentObservation prevObservation];
    if (prevObservation) {
        ObservationDetailViewController *pvc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"ObservationDetailViewController"];
        pvc.observation = prevObservation;
        pvc.delegate = vc.delegate;
        [vc save];
        return pvc;
    }
    return nil;
}

@end
