//
//  GuidePageViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 10/15/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import "GuidePageViewController.h"
#import "GuideTaxonViewController.h"
#import "Observation.h"
#import "UIColor+INaturalist.h"

@implementation GuidePageViewController
@synthesize guide = _guide;
@synthesize currentPosition = _currentPosition;
@synthesize currentXPath = _currentXPath;

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.viewControllers == nil || self.viewControllers.count == 0) {
        GuideTaxonViewController *gtvc = [self.storyboard instantiateViewControllerWithIdentifier:@"GuideTaxonViewController"];
        RXMLElement *rx = [self.guide atXPath:[NSString stringWithFormat:@"(%@)[%ld]", [self currentXPath], (long)self.currentPosition]];
        gtvc.guideTaxon = [[GuideTaxonXML alloc] initWithGuide:self.guide andXML:rx];
        gtvc.localPosition = self.currentPosition;
        [self setViewControllers:[NSArray arrayWithObject:gtvc]
                       direction:UIPageViewControllerNavigationDirectionForward
                        animated:YES
                      completion:nil];
    }
    self.dataSource = self;
    self.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.translucent = NO;
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor inatTint];
}

#pragma mark - UIPageViewControllerDelegate
- (void)pageViewController:(UIPageViewController *)pageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray *)previousViewControllers
       transitionCompleted:(BOOL)completed
{
    if (completed) {
        GuideTaxonViewController *cvc = (GuideTaxonViewController *)self.viewControllers.lastObject;
        self.currentPosition = cvc.localPosition;
        self.title = cvc.title;
    }
}

#pragma mark - GuidePageDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    return [self viewControllerAtPosition:self.currentPosition+1];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    return [self viewControllerAtPosition:self.currentPosition-1];
}

#pragma mark - GuidePageViewController

- (GuideTaxonViewController *)viewControllerAtPosition:(NSInteger)position
{
    RXMLElement *rx = [self.guide atXPath:[NSString stringWithFormat:@"(%@)[%ld]", [self currentXPath], (long)position]];
    if (rx) {
        GuideTaxonViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"GuideTaxonViewController"];
        vc.guideTaxon = [[GuideTaxonXML alloc] initWithGuide:self.guide andXML:rx];
        vc.localPosition = position;
        return vc;
    }
    return nil;
}

- (IBAction)clickedObserve:(id)sender {
    GuideTaxonViewController *gtvc = self.viewControllers.lastObject;
    [gtvc clickedObserve:sender];
}
@end
