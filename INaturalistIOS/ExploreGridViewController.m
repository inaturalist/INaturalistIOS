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
#import <PDKTStickySectionHeadersCollectionViewLayout/PDKTStickySectionHeadersCollectionViewLayout.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "ExploreGridViewController.h"
#import "ExploreObservationPhoto.h"
#import "ExploreObservation.h"
#import "ExploreObservationDetailViewController.h"
#import "ExploreGridCell.h"
#import "UIColor+ExploreColors.h"
#import "Analytics.h"
#import "RestrictedCollectionHeader.h"

static NSString *ExploreGridCellId = @"ExploreCell";
static NSString *ExploreGridHeaderId = @"ExploreHeader";

@interface ExploreGridViewController () <UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout> {
    UICollectionView *observationsCollectionView;
}
@end

@implementation ExploreGridViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    observationsCollectionView = ({
        UICollectionViewFlowLayout *flowLayout = [[PDKTStickySectionHeadersCollectionViewLayout alloc] init];
        
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
        
        [cv registerClass:[ExploreGridCell class] forCellWithReuseIdentifier:ExploreGridCellId];
        [cv registerClass:[RestrictedCollectionHeader class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:ExploreGridHeaderId];
        
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
    
    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateExploreGrid];
    
    // ensure the collection view is up to date
    // this isn't always happening automatically from -observationChangedCallback
    // on the iPhone 4s for some reason
    [observationsCollectionView reloadData];
    
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateExploreGrid];
    
    [super viewDidDisappear:animated];
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
    ExploreGridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ExploreGridCellId
                                                                      forIndexPath:indexPath];
    [cell setObservation:[self.observationDataSource.observations objectAtIndex:indexPath.item]];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        RestrictedCollectionHeader *header = (RestrictedCollectionHeader *)[collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                                                              withReuseIdentifier:ExploreGridHeaderId
                                                                                                                     forIndexPath:indexPath];
        
        header.titleLabel.text = NSLocalizedString(@"Restricted to current map area", nil);
        [header.clearButton addTarget:self
                               action:@selector(tappedClearMapRestriction:)
                     forControlEvents:UIControlEventTouchUpInside];
        
        return header;
    }
}



- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if ([self.observationDataSource activeSearchLimitedByCurrentMapRegion] && self.observationDataSource.observations.count > 0)
        return CGSizeMake(collectionView.frame.size.width, 44);
    else
        return CGSizeMake(0, 0);
}

#pragma mark - UIControl targets

- (void)tappedClearMapRestriction:(UIControl *)control {
    self.observationDataSource.limitingRegion = nil;
}

#pragma mark - ExploreViewControllerControlIcon

- (UIImage *)controlIcon {
    FAKIcon *grid = [FAKFoundationIcons thumbnailsIconWithSize:22.0f];
    [grid addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
    return [grid imageWithSize:CGSizeMake(25.0f, 25.0f)];
}

@end
