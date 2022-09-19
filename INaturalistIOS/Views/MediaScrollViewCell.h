//
//  MediaScrollViewCell.h
//  
//
//  Created by Alex Shepard on 10/22/15.
//
//

#import <UIKit/UIKit.h>

@class MediaScrollViewCell;

@protocol MediaScrollViewDelegate <NSObject>
- (void)mediaScrollView:(MediaScrollViewCell *)psv deletedIndex:(NSInteger)idx;
- (void)mediaScrollView:(MediaScrollViewCell *)psv setDefaultIndex:(NSInteger)idx;
- (void)mediaScrollViewAddPressed:(MediaScrollViewCell *)psv;
- (void)mediaScrollView:(MediaScrollViewCell *)psv selectedIndex:(NSInteger)idx;
@end


@interface MediaScrollViewCell : UITableViewCell

@property (assign) id <MediaScrollViewDelegate> delegate;
@property NSArray *media;
@property UICollectionView *collectionView;

- (UIImageView *)imageViewForIndex:(NSInteger)idx;

@end
