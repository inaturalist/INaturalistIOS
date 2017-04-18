//
//  ExploreGridViewController.m
//  Explore Prototype
//
//  Created by Alex Shepard on 9/12/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonIcons.h>
#import <FontAwesomeKit/FAKFoundationIcons.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <SVPullToRefresh/SVPullToRefresh.h>
#import <PDKTStickySectionHeadersCollectionViewLayout/PDKTStickySectionHeadersCollectionViewLayout.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "ExploreGridViewController.h"
#import "ExploreObservationPhoto.h"
#import "ExploreObservation.h"
#import "ExploreGridCell.h"
#import "UIColor+ExploreColors.h"
#import "Analytics.h"
#import "RestrictedCollectionHeader.h"
#import "ObsDetailV2ViewController.h"

static NSString *ExploreGridCellId = @"ExploreCell";
static NSString *ExploreGridHeaderId = @"ExploreHeader";

@interface ExploreGridViewController () <UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout> {
    UICollectionView *observationsCollectionView;
    UICollectionViewFlowLayout *flowLayout;
}
@end

@implementation ExploreGridViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    observationsCollectionView = ({
        flowLayout = [[PDKTStickySectionHeadersCollectionViewLayout alloc] init];
        flowLayout.minimumInteritemSpacing = 2.0f;
        flowLayout.minimumLineSpacing = 2.0f;
        // this will get reset once layout is done
      	float itemWidth = (self.view.bounds.size.width / 3) - 2.0f;
		flowLayout.itemSize = CGSizeMake(itemWidth, itemWidth);
        
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
    [super viewDidAppear:animated];

    // presenting from this collection view is screwing up the content inset
    // reset it here
    observationsCollectionView.contentInset = [self insetsForPredicateCount:self.observationDataSource.activeSearchPredicates.count];
    
  	[self configureFlowLayout:flowLayout inCollectionView:observationsCollectionView forTraits:self.traitCollection];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    	[self configureFlowLayout:flowLayout inCollectionView:observationsCollectionView forTraits:self.traitCollection];
    }];
}

#pragma mark - UI Helper

- (void)configureFlowLayout:(UICollectionViewFlowLayout *)layout inCollectionView:(UICollectionView *)cv forTraits:(UITraitCollection *)traits {
	float numberOfCellsPerRow = 3;        
   	if (traits.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
   		numberOfCellsPerRow = 5;
   	}
	float itemWidth = (cv.bounds.size.width / numberOfCellsPerRow) - 2.0f;
	layout.itemSize = CGSizeMake(itemWidth, itemWidth);
	[cv reloadData];
}

 
- (UIEdgeInsets)insetsForPredicateCount:(NSInteger)count {
    CGFloat topInset = 0.0f;
    if (count > 0)
        topInset = 51.0f;
    
    return UIEdgeInsetsMake(topInset, 0, 0, 0);
}

#pragma mark - KVO

- (void)observationChangedCallback {
    dispatch_async(dispatch_get_main_queue(), ^{
        // in case refresh was triggered by infinite scrolling, stop the animation
        [observationsCollectionView.infiniteScrollingView stopAnimating];
        
        [observationsCollectionView reloadData];
        
        // if necessary, inset the collection view content inside the container
        // to make room for the active search text
        observationsCollectionView.contentInset = [self insetsForPredicateCount:self.observationDataSource.activeSearchPredicates.count];
    });
}

#pragma mark - UICollectionView delegate/datasource

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    ObsDetailV2ViewController *obsDetail = [mainStoryboard instantiateViewControllerWithIdentifier:@"obsDetailV2"];
    ExploreObservation *selectedObservation = [self.observationDataSource.observationsWithPhotos objectAtIndex:indexPath.item];
    obsDetail.observation = selectedObservation;
    [self.navigationController pushViewController:obsDetail animated:YES];
    [[Analytics sharedClient] event:kAnalyticsEventNavigateObservationDetail
                     withProperties:@{ @"via": @"Explore Grid" }];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.observationDataSource.observationsWithPhotos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ExploreGridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ExploreGridCellId
                                                                      forIndexPath:indexPath];
    [cell setObservation:[self.observationDataSource.observationsWithPhotos objectAtIndex:indexPath.item]];
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
    } else {
        // not supposed to return nil from this method
        UICollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                            withReuseIdentifier:@"Unused"
                                                                                   forIndexPath:indexPath];
        view.hidden = YES;
        return view;
    }
}



- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if ([self.observationDataSource activeSearchLimitedByCurrentMapRegion] && self.observationDataSource.observationsWithPhotos.count > 0)
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
