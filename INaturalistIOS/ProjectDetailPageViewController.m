//
//  ProjectDetailPageViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "ProjectDetailPageViewController.h"
#import "ProjectsAPI.h"
#import "ProjectDetailObservationsViewController.h"
#import "ProjectDetailSpeciesViewController.h"
#import "ProjectDetailObserversViewController.h"
#import "ProjectDetailIdentifiersViewController.h"
#import "ContainedScrollViewDelegate.h"
#import "UIColor+INaturalist.h"

@interface ViewPagerController ()
- (void)selectTabAtIndex:(NSUInteger)index didSwipe:(BOOL)didSwipe;
@end

@interface ProjectDetailPageViewController () <ViewPagerDataSource, ViewPagerDelegate>
@property ProjectsAPI *api;

@property ProjectDetailObservationsViewController *projObservationsVC;
@property ProjectDetailSpeciesViewController *projSpeciesVC;
@property ProjectDetailObserversViewController *projObserversVC;
@property ProjectDetailIdentifiersViewController *projIdentifiersVC;

@property NSInteger numObservations;
@property NSInteger numSpecies;
@property NSInteger numObservers;
@property NSInteger numIdentifers;

@end

@implementation ProjectDetailPageViewController

-(void)viewDidLoad {
    self.dataSource = self;
    self.delegate = self;
    
    self.numObservations = 0;
    self.numSpecies = 0;
    self.numObservers = 0;
    self.numIdentifers = 0;
    
    self.projObservationsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"projObservationsVC"];
    self.projObservationsVC.projectDetailDelegate = self.projectDetailDelegate;
    self.projObservationsVC.containedScrollViewDelegate = self.containedScrollViewDelegate;
    
    self.projSpeciesVC = [self.storyboard instantiateViewControllerWithIdentifier:@"projSpeciesVC"];
    self.projSpeciesVC.projectDetailDelegate = self.projectDetailDelegate;
    self.projSpeciesVC.containedScrollViewDelegate = self.containedScrollViewDelegate;
    
    self.projObserversVC = [self.storyboard instantiateViewControllerWithIdentifier:@"projObserversVC"];
    self.projObserversVC.projectDetailDelegate = self.projectDetailDelegate;
    self.projObserversVC.containedScrollViewDelegate = self.containedScrollViewDelegate;
    
    self.projIdentifiersVC = [self.storyboard instantiateViewControllerWithIdentifier:@"projIdentifiersVC"];
    self.projIdentifiersVC.projectDetailDelegate = self.projectDetailDelegate;
    self.projIdentifiersVC.containedScrollViewDelegate = self.containedScrollViewDelegate;
        
    self.api = [[ProjectsAPI alloc] init];
    [self.api observationsForProject:self.project handler:^(NSArray *results, NSInteger totalCount, NSError *error) {
        self.projObservationsVC.observations = results;
        self.numObservations = totalCount;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadData];
            [self.projObservationsVC.collectionView reloadData];
        });
    }];
    
    [self.api speciesCountsForProject:self.project handler:^(NSArray *results, NSInteger totalCount, NSError *error) {
        self.projSpeciesVC.speciesCounts = results;
        self.numSpecies = totalCount;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadData];
            [self.projSpeciesVC.tableView reloadData];
        });
    }];
    
    [self.api observerCountsForProject:self.project handler:^(NSArray *results, NSInteger totalCount, NSError *error) {
        self.projObserversVC.observerCounts = results;
        self.numObservers = totalCount;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadData];
            [self.projObserversVC.tableView reloadData];
        });
    }];
    
    [self.api identifierCountsForProject:self.project handler:^(NSArray *results, NSInteger totalCount, NSError *error) {
        self.projIdentifiersVC.identifierCounts = results;
        self.numIdentifers = totalCount;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadData];
            [self.projIdentifiersVC.tableView reloadData];
        });
    }];
}

#pragma mark - UIViewPagerDelegate

-(CGFloat)viewPager:(ViewPagerController *)viewPager valueForOption:(ViewPagerOption)option withDefault:(CGFloat)value {
    switch (option) {
        case ViewPagerOptionCenterCurrentTab:
            return 1.0f;
            break;
        case ViewPagerOptionTabHeight:
            return 52.0f;
            break;
        case ViewPagerOptionTabWidth:
            return self.parentViewController.view.bounds.size.width / 3.5f;
            break;
        default:
            return value;
            break;
    }
}

#pragma mark - UIViewPagerDataSource

- (NSUInteger)numberOfTabsForViewPager:(ViewPagerController *)viewPager {
    return 4;
}

- (UIColor *)viewPager:(ViewPagerController *)viewPager colorForComponent:(ViewPagerComponent)component withDefault:(UIColor *)color {
    switch (component ) {
        case ViewPagerIndicator:
            return [UIColor inatTint];
        case ViewPagerContent:
            return color;
        case ViewPagerTabsView:
            return [UIColor whiteColor];
    }
}


// separator #efeff4

- (UIView *)viewPager:(ViewPagerController *)viewPager viewForTabAtIndex:(NSUInteger)index {
    
    UIView *tab = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.parentViewController.view.bounds.size.width / 3.5f, 52.0f)];
    
    CGFloat width = self.parentViewController.view.bounds.size.width / 3.5f;
    if (index < 3) {
        width = width - 0.5f;
    }
    UILabel *label = [UILabel new];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 2;
    label.textAlignment = NSTextAlignmentCenter;
    
    NSInteger *count;
    NSString *title;
    
    switch (index) {
        case 0:
            count = self.numObservations;
            title = @"OBSERVATIONS";
            break;
        case 1:
            count = self.numSpecies;
            title = @"SPECIES";
            break;
        case 2:
            count = self.numObservers;
            title = @"OBSERVERS";
            break;
        case 3:
            count = self.numIdentifers;
            title = @"IDENTIFIERS";
            break;
        default:
            count = 0;
            title = @"";
            break;
    }
    
    NSString *countText = [NSString stringWithFormat:@"%ld\n", (long)count];
    NSDictionary *countAttrs = @{
                                 NSFontAttributeName: [UIFont systemFontOfSize:20],
                                 NSForegroundColorAttributeName: [UIColor inatTint],
                                 };
    NSDictionary *titleAttrs = @{
                                 NSFontAttributeName: [UIFont systemFontOfSize:11],
                                 NSForegroundColorAttributeName: [UIColor colorWithHexString:@"#999999"],
                                 };
    NSMutableAttributedString *labelText = [[NSMutableAttributedString alloc] initWithString:countText
                                                                                  attributes:countAttrs];
    [labelText appendAttributedString:[[NSAttributedString alloc] initWithString:title
                                                                      attributes:titleAttrs]];
    
    [label setAttributedText:labelText];

    [tab addSubview:label];
    
    UIView *separator = [UIView new];
    separator.translatesAutoresizingMaskIntoConstraints = NO;
    if (index == 3) {
        separator.backgroundColor = [UIColor clearColor];
    } else {
        separator.backgroundColor = [UIColor colorWithHexString:@"#efeff4"];
    }
    [tab addSubview:separator];
    
    NSDictionary *views = @{
                            @"separator": separator,
                            @"label": label,
                            };
    
    [tab addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[label]|"
                                                                options:0
                                                                metrics:0
                                                                  views:views]];
    [tab addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[separator(==0.5)]|"
                                                                options:0
                                                                metrics:0
                                                                  views:views]];
    
    [tab addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]|"
                                                                options:0
                                                                metrics:0
                                                                  views:views]];
    [tab addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-11-[separator]-11-|"
                                                                options:0
                                                                metrics:0
                                                                  views:views]];
    
    return tab;
}

- (void)selectTabAtIndex:(NSUInteger)index didSwipe:(BOOL)didSwipe {
    self.projObservationsVC.containedScrollViewDelegate = nil;
    self.projSpeciesVC.containedScrollViewDelegate = nil;
    self.projObserversVC.containedScrollViewDelegate = nil;
    self.projIdentifiersVC.containedScrollViewDelegate = nil;
    
    [self.containedScrollViewDelegate containedScrollViewDidReset:nil];
    
    switch (index) {
        case 0:
            [self.projObservationsVC.collectionView setContentOffset:CGPointMake(0, 0) animated:NO];
            self.projObservationsVC.containedScrollViewDelegate = self.containedScrollViewDelegate;
            break;
        case 1:
            [self.projSpeciesVC.tableView setContentOffset:CGPointMake(0, 0) animated:NO];
            self.projSpeciesVC.containedScrollViewDelegate = self.containedScrollViewDelegate;
        case 2:
            [self.projObserversVC.tableView setContentOffset:CGPointMake(0, 0) animated:NO];
            self.projObserversVC.containedScrollViewDelegate = self.containedScrollViewDelegate;
            
        case 3:
            [self.projIdentifiersVC.tableView setContentOffset:CGPointMake(0, 0) animated:NO];
            self.projIdentifiersVC.containedScrollViewDelegate = self.containedScrollViewDelegate;
            
        default:
            break;
    }
    
    [super selectTabAtIndex:index didSwipe:didSwipe];
}

- (void)selectTabAtIndex:(NSUInteger)index {
    [self selectTabAtIndex:index didSwipe:NO];
}

- (UIViewController *)viewPager:(ViewPagerController *)viewPager contentViewControllerForTabAtIndex:(NSUInteger)index {
    switch (index) {
        case 0:
            return self.projObservationsVC;
            break;
        case 1:
            return self.projSpeciesVC;
            break;
        case 2:
            return self.projObserversVC;
            break;
        case 3:
            return self.projIdentifiersVC;
            break;
        default:
            return [[UIViewController alloc] initWithNibName:nil bundle:nil];
            break;
    }
}

@end
