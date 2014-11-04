//
//  ExploreGridViewController.m
//  Explore Prototype
//
//  Created by Alex Shepard on 9/12/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <FontAwesomeKit/FAKFoundationIcons.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <SVPullToRefresh/SVPullToRefresh.h>

#import "ExploreGridViewController.h"
#import "ExploreObservationPhoto.h"
#import "ExploreObservation.h"
#import "ExploreObservationDetailViewController.h"
#import "ExploreGridCell.h"
#import "UIColor+ExploreColors.h"
#import "Analytics.h"

@interface ExploreGridViewController () <UICollectionViewDataSource,UICollectionViewDelegate> {
    UICollectionView *observationsCollectionView;
}
@end

@implementation ExploreGridViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    observationsCollectionView = ({
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        
        float numberOfCellsPerRow = 3;
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            numberOfCellsPerRow = 5;
        }
        float shortestSide = MIN(self.view.frame.size.width, self.view.frame.size.height);
        float itemWidth = (shortestSide / numberOfCellsPerRow) - 2.0f;
        flowLayout.itemSize = CGSizeMake(itemWidth, itemWidth);
        flowLayout.minimumInteritemSpacing = 2.0f;
        flowLayout.minimumLineSpacing = 2.0f;
        
        
        // use autolayout
        UICollectionView *cv = [[UICollectionView alloc] initWithFrame:CGRectZero
                                                  collectionViewLayout:flowLayout];
        cv.translatesAutoresizingMaskIntoConstraints = NO;
        
        cv.backgroundColor = [UIColor whiteColor];
        cv.dataSource = self;
        cv.delegate = self;
        
        [cv registerClass:[ExploreGridCell class] forCellWithReuseIdentifier:@"ExploreCell"];
        
        __weak __typeof__(self) weakSelf = self;
        [cv addInfiniteScrollingWithActionHandler:^{
            [weakSelf.observationDataSource expandActiveSearchToNextPageOfResults];
        }];
        cv.showsInfiniteScrolling = YES;

        
        cv;
    });
    [self.view addSubview:observationsCollectionView];
    
    NSDictionary *views = @{
                            @"topLayoutGuide": self.topLayoutGuide,
                            @"bottomLayoutGuide": self.bottomLayoutGuide,
                            @"observationsCollectionView": observationsCollectionView,
                            };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[observationsCollectionView]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[topLayoutGuide]-0-[observationsCollectionView]-0-[bottomLayoutGuide]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    
    if (observationsCollectionView.visibleCells.count > 0)
        [observationsCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                                           atScrollPosition:UICollectionViewScrollPositionTop
                                                   animated:YES];
    
    observationsCollectionView.contentInset = [self insetsForPredicateCount:self.observationDataSource.activeSearchPredicates.count];
    
}

- (void)viewDidAppear:(BOOL)animated {
    // presenting from this collection view is screwing up the content inset
    // reset it here
    observationsCollectionView.contentInset = [self insetsForPredicateCount:self.observationDataSource.activeSearchPredicates.count];

    [super viewDidAppear:animated];
    
    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateExploreGrid];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateExploreGrid];
}

#pragma mark - UI Helper

- (UIEdgeInsets)insetsForPredicateCount:(NSInteger)count {
    CGFloat topInset = 0.0f;
    if (count > 0)
        topInset = 51.0f;
    
    return UIEdgeInsetsMake(topInset, 0, 0, 0);
}

#pragma mark - KVO

- (void)observationChangedCallback {
    // in case refresh was triggered by infinite scrolling, stop the animation
    [observationsCollectionView.infiniteScrollingView stopAnimating];

    [observationsCollectionView reloadData];
    
    // if necessary, inset the collection view content inside the container
    // to make room for the active search text
    observationsCollectionView.contentInset = [self insetsForPredicateCount:self.observationDataSource.activeSearchPredicates.count];

    // the collection view seems to need to be forced to re-layout before it
    // can properly scroll to the first item using the new content insets
    [self.view layoutIfNeeded];
    
    if (self.observationDataSource.latestSearchShouldResetUI && self.observationDataSource.observations.count > 0) {
        [observationsCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                                           atScrollPosition:UICollectionViewScrollPositionTop
                                                   animated:YES];
    }
}

#pragma mark - UICollectionView delegate/datasource

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
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

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.observationDataSource.observations.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ExploreGridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ExploreCell"
                                                                      forIndexPath:indexPath];
    [cell setObservation:[self.observationDataSource.observations objectAtIndex:indexPath.item]];
    return cell;
}

#pragma mark - ExploreViewControllerControlIcon

- (UIImage *)controlIcon {
    FAKIcon *grid = [FAKFoundationIcons thumbnailsIconWithSize:22.0f];
    [grid addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
    return [grid imageWithSize:CGSizeMake(25.0f, 25.0f)];
}

@end
