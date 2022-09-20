//
//  MediaScrollViewCell.m
//  
//
//  Created by Alex Shepard on 10/22/15.
//
//

#import <FontAwesomeKit/FAKIonIcons.h>
#import <AFNetworking/UIImageView+AFNetworking.h>

#import "MediaScrollViewCell.h"
#import "PhotoChicletCell.h"
#import "ObservationPhoto.h"
#import "ImageStore.h"
#import "AddChicletCell.h"
#import "INatSound.h"
#import "iNaturalist-Swift.h"
#import "ExploreObservationSoundRealm.h"

static NSAttributedString *defaultPhotoStr, *nonDefaultPhotoStr;

@interface MediaScrollViewCell () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property NSAttributedString *defaultPhotoStr, *nonDefaultPhotoStr;
@end

@implementation MediaScrollViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        self.collectionView = ({
            UICollectionViewFlowLayout *flow = [[UICollectionViewFlowLayout alloc] init];
            flow.scrollDirection = UICollectionViewScrollDirectionHorizontal;
            
            UICollectionView *cv = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flow];
            cv.translatesAutoresizingMaskIntoConstraints = NO;
            
            cv.backgroundColor = [UIColor whiteColor];
            
            cv.delegate = self;
            cv.dataSource = self;
            
            [cv registerClass:[PhotoChicletCell class] forCellWithReuseIdentifier:@"photoChiclet"];
            [cv registerClass:[AddChicletCell class] forCellWithReuseIdentifier:@"addChiclet"];
            
            cv;
        });
        [self.contentView addSubview:self.collectionView];
        
        NSDictionary *views = @{ @"cv": self.collectionView };
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-7.5-[cv]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[cv]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        FAKIcon *check = [FAKIonIcons iosCheckmarkOutlineIconWithSize:18];
        NSMutableAttributedString *defaultPhotoMutable = [[NSMutableAttributedString alloc] initWithAttributedString:check.attributedString];
        [defaultPhotoMutable appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
        [defaultPhotoMutable appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Default", nil)
                                                                                    attributes:@{
                                                                                                 NSFontAttributeName: [UIFont systemFontOfSize:12],
                                                                                                 }]];
        self.defaultPhotoStr = [[NSAttributedString alloc] initWithAttributedString:defaultPhotoMutable];
        
        FAKIcon *circle = [FAKIonIcons iosCircleOutlineIconWithSize:18];
        self.nonDefaultPhotoStr = [circle attributedString];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.media = nil;
    [self.collectionView reloadData];
}

- (UIImageView *)imageViewForIndex:(NSInteger)idx {
    PhotoChicletCell *cell = (PhotoChicletCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:idx+1 inSection:0]];
    return cell.photoImageView;
}

#pragma mark - UIButton targets

- (void)deletePressed:(UIButton *)button {
    UICollectionViewCell *cell = (PhotoChicletCell *)button.superview.superview;
    NSIndexPath *ip = [self.collectionView indexPathForCell:cell];
    
    id obsMediaItem = self.media[ip.item-1];
    NSMutableArray *mutableMedia = [self.media mutableCopy];
    [mutableMedia removeObject:obsMediaItem];
    self.media = [NSArray arrayWithArray:mutableMedia];
    
    [self.collectionView deleteItemsAtIndexPaths:@[ ip ]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.33 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.delegate mediaScrollView:self deletedIndex:ip.item - 1];
    });
}

- (void)defaultPressed:(UIButton *)button {
    PhotoChicletCell *cell = (PhotoChicletCell *)button.superview.superview;
    NSIndexPath *ip = [self.collectionView indexPathForCell:cell];
    
    id obsMediaItem = self.media[ip.item-1];
    NSMutableArray *mutableMedia = [self.media mutableCopy];
    [mutableMedia removeObject:obsMediaItem];
    [mutableMedia insertObject:obsMediaItem atIndex:0];
    self.media = [NSArray arrayWithArray:mutableMedia];
    
    [self.collectionView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    
    [self.collectionView bringSubviewToFront:cell];
    [self.collectionView moveItemAtIndexPath:ip
                                 toIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];
    
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.33 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.delegate mediaScrollView:self setDefaultIndex:ip.item-1];
    });
}


#pragma mark - UICollectionView delegate/datasource

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item < 1) {
        // add cell
        AddChicletCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"addChiclet" forIndexPath:indexPath];
        
        return cell;
    } else {
        PhotoChicletCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"photoChiclet" forIndexPath:indexPath];
        
        id mediaItem = self.media[indexPath.item - 1];
        if ([mediaItem conformsToProtocol:@protocol(INatPhoto)]) {
            id <INatPhoto> obsPhoto = self.media[indexPath.item - 1];
            if (obsPhoto.photoKey) {
                cell.photoImageView.image = [[ImageStore sharedImageStore] find:obsPhoto.photoKey
                                                                        forSize:ImageStoreSquareSize];
            }
            if (!cell.photoImageView.image) {
                if ([obsPhoto squarePhotoUrl]) {
                    [cell.photoImageView setImageWithURL:[obsPhoto squarePhotoUrl]];
                }
            }
            
            [cell.deleteButton addTarget:self action:@selector(deletePressed:) forControlEvents:UIControlEventTouchUpInside];
            [cell.defaultButton addTarget:self action:@selector(defaultPressed:) forControlEvents:UIControlEventTouchUpInside];
            cell.defaultButton.hidden = FALSE;
        } else if ([mediaItem conformsToProtocol:@protocol(INatSound)]) {
            
            FAKIonIcons *soundIcon = [FAKIonIcons iosVolumeHighIconWithSize:40];
            
            [soundIcon addAttribute:NSForegroundColorAttributeName
                              value:[UIColor lightGrayColor]];
            
            cell.photoImageView.image = [soundIcon imageWithSize:CGSizeMake(40, 40)];
            cell.photoImageView.contentMode = UIViewContentModeCenter;  // don't scale

            [cell.deleteButton addTarget:self action:@selector(deletePressed:) forControlEvents:UIControlEventTouchUpInside];
            [cell.defaultButton removeTarget:self action:@selector(defaultPressed:) forControlEvents:UIControlEventTouchUpInside];
            cell.defaultButton.hidden = TRUE;
        }
        
        
        if (indexPath.item == 1) {
            [cell.defaultButton setAttributedTitle:self.defaultPhotoStr forState:UIControlStateNormal];
        } else {
            [cell.defaultButton setAttributedTitle:self.nonDefaultPhotoStr forState:UIControlStateNormal];
        }

        return cell;
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.media.count + 1;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(71 + 18, collectionView.bounds.size.height);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == 0) {
        [self.delegate mediaScrollViewAddPressed:self];
    } else {
        [self.delegate mediaScrollView:self selectedIndex:indexPath.item - 1];
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

@end
