//
//  ExploreListViewController.m
//  Explore Prototype
//
//  Created by Alex Shepard on 9/12/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

@import BlocksKit;
@import FontAwesomeKit;
@import SVPullToRefresh;
@import UIColor_HTMLColors;

#import "ExploreListViewController.h"
#import "ExploreObservation.h"
#import "ExploreObservationPhoto.h"
#import "ExploreListTableViewCell.h"
#import "UIColor+ExploreColors.h"
#import "RestrictedListHeader.h"
#import "ObsDetailV2ViewController.h"

static NSString *ExploreListCellId = @"ExploreListCell";
static NSString *ExploreListHeaderId = @"ExploreListHeader";

@interface ExploreListViewController () <UITableViewDataSource,UITableViewDelegate>
@property UITableView *observationsTableView;
@end

@implementation ExploreListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.observationsTableView = ({
        // use autolayout
        UITableView *tv = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        tv.translatesAutoresizingMaskIntoConstraints = NO;
        
        tv.rowHeight = 105.0f;
        tv.separatorColor = [UIColor clearColor];
        
        tv.dataSource = self;
        tv.delegate = self;
        [tv registerClass:[ExploreListTableViewCell class] forCellReuseIdentifier:ExploreListCellId];
        [tv registerClass:[RestrictedListHeader class] forHeaderFooterViewReuseIdentifier:ExploreListHeaderId];
        
        __weak __typeof__(self) weakSelf = self;
        [tv addInfiniteScrollingWithActionHandler:^{
            [weakSelf.observationDataSource expandActiveSearchToNextPageOfResults];
        }];
        tv.showsInfiniteScrolling = YES;
        
        tv;
    });
    [self.view addSubview:self.observationsTableView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.observationsTableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.observationsTableView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        [self.observationsTableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.observationsTableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    ]];

    [self.observationsTableView layoutIfNeeded];
    [self.observationsTableView reloadData];
    
    self.observationsTableView.contentInset = [self insetsForPredicateCount:self.observationDataSource.activeSearchPredicates.count];
    
    if (self.observationsTableView.visibleCells.count > 0)
        [self.observationsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                                          atScrollPosition:UITableViewScrollPositionTop
                                                  animated:YES];
}

- (void)viewWillLayoutSubviews {
    
    [super viewWillLayoutSubviews];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // presenting from this collection view is screwing up the content inset
    // reset it here
    self.observationsTableView.contentInset = [self insetsForPredicateCount:self.observationDataSource.activeSearchPredicates.count];
}

#pragma mark - UI Helper

- (UIEdgeInsets)insetsForPredicateCount:(NSInteger)count {
    CGFloat topInset = 0.0f;
    if (count > 0)
        topInset = 50.0f;
    
    return UIEdgeInsetsMake(topInset, 0, 0, 0);
}

#pragma mark - KVO callback

- (void)observationChangedCallback {
    dispatch_async(dispatch_get_main_queue(), ^{
        // in case refresh was triggered by infinite scrolling, stop the animation
        [self.observationsTableView.infiniteScrollingView stopAnimating];
        
        [self.observationsTableView reloadData];
        
        // if necessary, adjust the content inset of the table view
        // to make room for the active search predicate
        self.observationsTableView.contentInset = [self insetsForPredicateCount:self.observationDataSource.activeSearchPredicates.count];
    });
}

#pragma mark - UITableView delegate/datasource

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    ObsDetailV2ViewController *obsDetail = [mainStoryboard instantiateViewControllerWithIdentifier:@"obsDetailV2"];
    ExploreObservation *selectedObservation = [self.observationDataSource.observations objectAtIndex:indexPath.item];
    obsDetail.observation = selectedObservation;
    [self.navigationController pushViewController:obsDetail animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 105.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 105.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [self.observationDataSource activeSearchLimitedByCurrentMapRegion] ? 44.0f : 0.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.observationDataSource.observations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ExploreListTableViewCell *cell = (ExploreListTableViewCell *)[tableView dequeueReusableCellWithIdentifier:ExploreListCellId];
    
    ExploreObservation *obs = [self.observationDataSource.observations objectAtIndex:indexPath.item];
    [cell setObservation:obs];
        
    return cell;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if ([self.observationDataSource activeSearchLimitedByCurrentMapRegion]) {
        RestrictedListHeader *header = (RestrictedListHeader *)[tableView dequeueReusableHeaderFooterViewWithIdentifier:ExploreListHeaderId];
    
        header.titleLabel.text = NSLocalizedString(@"Restricted to current map area", nil);
        [header.clearButton addTarget:self
                               action:@selector(tappedClearMapRestriction:)
                     forControlEvents:UIControlEventTouchUpInside];
    
        return header;
    } else {
        return nil;
    }
}

#pragma mark - UIControl targets

- (void)tappedClearMapRestriction:(UIControl *)control {
    self.observationDataSource.limitingRegion = nil;
}

#pragma mark - ExploreViewControllerControlIcon

- (UIImage *)controlIcon {
    FAKIcon *list = [FAKFoundationIcons listIconWithSize:22.0f];
    [list addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
    return [list imageWithSize:CGSizeMake(25.0f, 25.0f)];
}

@end
