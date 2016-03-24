//
//  ProjectDetailObservationsViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <DZNEmptyDataSet/UIScrollView+EmptyDataSet.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "ProjectDetailObservationsViewController.h"
#import "ExploreObservation.h"
#import "ExploreObservationPhoto.h"
#import "ProjectObsPhotoCell.h"
#import "ImageStore.h"
#import "FAKInaturalist.h"

@interface ProjectDetailObservationsViewController () <UICollectionViewDelegateFlowLayout, DZNEmptyDataSetSource>
@end

@implementation ProjectDetailObservationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView.emptyDataSetSource = self;
    self.totalCount = 0;
    self.collectionView.backgroundColor = [UIColor whiteColor];
}

#pragma mark - CollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.observations.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    ProjectObsPhotoCell *cell = (ProjectObsPhotoCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"observation"
                                                                           forIndexPath:indexPath];
    
    ExploreObservation *obs = (ExploreObservation *)self.observations[indexPath.item];
    ExploreObservationPhoto *photo = obs.observationPhotos.firstObject;
    if (photo) {
        NSString *mediumUrlString = [photo.url stringByReplacingOccurrencesOfString:@"square"
                                                                         withString:@"small"];
        [cell.photoImageView sd_setImageWithURL:[NSURL URLWithString:mediumUrlString]];
    } else {
        // show iconic taxon image
        FAKIcon *taxonIcon = [FAKINaturalist iconForIconicTaxon:obs.iconicTaxonName
                                                       withSize:90];
        
        [taxonIcon addAttribute:NSForegroundColorAttributeName
                          value:[UIColor lightGrayColor]];
        
        cell.photoImageView.image = [taxonIcon imageWithSize:CGSizeMake(90, 90)];
        cell.photoImageView.contentMode = UIViewContentModeTop;  // don't scale
    }
    cell.obsText.text = obs.speciesGuess;
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    ExploreObservation *obs = (ExploreObservation *)self.observations[indexPath.item];
    UIViewController *parent = self.parentViewController;
    UIViewController *grandParent = parent.parentViewController;
    UIViewController *greatGrandParent = grandParent.parentViewController;
    NSLog(@"greatGrandParent is %@", greatGrandParent);
    [greatGrandParent performSegueWithIdentifier:@"segueToObservationDetail"
                                          sender:obs];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat side = (collectionView.bounds.size.width / 3) - 1.0f;
    return CGSizeMake(side, side);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 1.0f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 1.0f;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.containedScrollViewDelegate containedScrollViewDidScroll:scrollView];
}

#pragma mark - DZNEmptyDataSource

- (UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView {
    if (self.observations == nil && [[RKClient sharedClient] isNetworkReachable]) {
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityView.color = [UIColor colorWithHexString:@"#8f8e94"];
        activityView.backgroundColor = [UIColor colorWithHexString:@"#ebebf1"];
        [activityView startAnimating];
        
        return activityView;
    } else {
        return nil;
    }
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *emptyTitle;
    if ([[RKClient sharedClient] isNetworkReachable]) {
        emptyTitle = NSLocalizedString(@"There are no observations for this project yet. Check back soon!", nil);
    } else {
        emptyTitle = NSLocalizedString(@"No network connection. :(", nil);
    }
    NSDictionary *attrs = @{
                            NSForegroundColorAttributeName: [UIColor colorWithHexString:@"#505050"],
                            NSFontAttributeName: [UIFont systemFontOfSize:17.0f],
                            };
    return [[NSAttributedString alloc] initWithString:emptyTitle
                                           attributes:attrs];
}

@end
