//
//  ExploreListViewController.m
//  Explore Prototype
//
//  Created by Alex Shepard on 9/12/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <FontAwesomeKit/FAKFoundationIcons.h>
#import <SVPullToRefresh/SVPullToRefresh.h>

#import "ExploreListViewController.h"
#import "ExploreObservation.h"
#import "ExploreObservationPhoto.h"
#import "ExploreListTableViewCell.h"
#import "ExploreObservationDetailViewController.h"
#import "UIColor+ExploreColors.h"
#import "Analytics.h"

@interface ExploreListViewController () <UITableViewDataSource,UITableViewDelegate> {
    UITableView *observationsTableView;
}
@end

@implementation ExploreListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    observationsTableView = ({
        // use autolayout
        UITableView *tv = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        tv.translatesAutoresizingMaskIntoConstraints = NO;
        
        tv.rowHeight = 105.0f;
        tv.separatorColor = [UIColor clearColor];
        
        tv.dataSource = self;
        tv.delegate = self;
        [tv registerClass:[ExploreListTableViewCell class] forCellReuseIdentifier:@"cell"];
        
        __weak __typeof__(self) weakSelf = self;
        [tv addInfiniteScrollingWithActionHandler:^{
            [weakSelf.observationDataSource expandActiveSearchToNextPageOfResults];
        }];
        tv.showsInfiniteScrolling = YES;
        
        tv;
    });
    [self.view addSubview:observationsTableView];
    
    NSDictionary *views = @{
                            @"topLayoutGuide": self.topLayoutGuide,
                            @"bottomLayoutGuide": self.bottomLayoutGuide,
                            @"observationsTableView": observationsTableView,
                            };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[observationsTableView]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[topLayoutGuide]-0-[observationsTableView]-0-[bottomLayoutGuide]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [observationsTableView layoutIfNeeded];
    [observationsTableView reloadData];
    
    observationsTableView.contentInset = [self insetsForPredicateCount:self.observationDataSource.activeSearchPredicates.count];
    
    if (observationsTableView.visibleCells.count > 0)
        [observationsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                                     atScrollPosition:UITableViewScrollPositionTop
                                             animated:YES];
}

- (void)viewWillLayoutSubviews {

    [super viewWillLayoutSubviews];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateExploreList];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateExploreList];
}

#pragma mark - UI Helper

- (UIEdgeInsets)insetsForPredicateCount:(NSInteger)count {
    CGFloat topInset = 0.0f;
    if (count > 0)
        topInset = 51.0f;
    
    return UIEdgeInsetsMake(topInset, 0, 0, 0);
}

#pragma mark - KVO callback

- (void)observationChangedCallback {
    // in case refresh was triggered by infinite scrolling, stop the animation
    [observationsTableView.infiniteScrollingView stopAnimating];

    [observationsTableView reloadData];

    // if necessary, adjust the content inset of the table view
    // to make room for the active search predicate
    observationsTableView.contentInset = [self insetsForPredicateCount:self.observationDataSource.activeSearchPredicates.count];
    
    if (self.observationDataSource.latestSearchWasViaUserInteration) {
        [observationsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                                     atScrollPosition:UITableViewScrollPositionTop
                                             animated:YES];
    }
}

#pragma mark - UITableView delegate/datasource

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ExploreObservationDetailViewController *detail = [[ExploreObservationDetailViewController alloc] initWithNibName:nil bundle:nil];
    detail.observation = [self.observationDataSource.observations objectAtIndex:indexPath.item];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:detail];
    
    // close icon
    FAKIcon *closeIcon = [FAKIonIcons ios7CloseEmptyIconWithSize:34.0f];
    [closeIcon addAttribute:NSForegroundColorAttributeName value:[UIColor inatGreen]];
    UIImage *closeImage = [closeIcon imageWithSize:CGSizeMake(25.0f, 34.0f)];
    
    UIBarButtonItem *close = [[UIBarButtonItem alloc] bk_initWithImage:closeImage
                                                                 style:UIBarButtonItemStylePlain
                                                               handler:^(id sender) {
                                                                   [self dismissViewControllerAnimated:YES completion:nil];
                                                               }];
    
    detail.navigationItem.leftBarButtonItem = close;
    
    [self presentViewController:nav animated:YES completion:nil];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 105.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 105.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.observationDataSource.observations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ExploreListTableViewCell *cell = (ExploreListTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    ExploreObservation *obs = [self.observationDataSource.observations objectAtIndex:indexPath.item];
    [cell setObservation:obs];
        
    return cell;
}

#pragma mark - ExploreViewControllerControlIcon

- (UIImage *)controlIcon {
    FAKIcon *list = [FAKFoundationIcons listIconWithSize:22.0f];
    [list addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
    return [list imageWithSize:CGSizeMake(25.0f, 25.0f)];
}

@end
