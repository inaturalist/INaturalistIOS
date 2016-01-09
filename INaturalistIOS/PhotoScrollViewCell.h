//
//  PhotoScrollViewCell.h
//  
//
//  Created by Alex Shepard on 10/22/15.
//
//

#import <UIKit/UIKit.h>

@class PhotoScrollViewCell;

@protocol PhotoScrollViewDelegate <NSObject>
- (void)photoScrollView:(PhotoScrollViewCell *)psv deletedIndex:(NSInteger)idx;
- (void)photoScrollView:(PhotoScrollViewCell *)psv setDefaultIndex:(NSInteger)idx;
- (void)photoScrollViewAddPressed:(PhotoScrollViewCell *)psv;
- (void)photoScrollView:(PhotoScrollViewCell *)psv selectedIndex:(NSInteger)idx;
@end


@interface PhotoScrollViewCell : UITableViewCell

@property (assign) id <PhotoScrollViewDelegate> delegate;
@property NSArray *photos;
@property UICollectionView *collectionView;

- (UIImageView *)imageViewForIndex:(NSInteger)idx;

@end
