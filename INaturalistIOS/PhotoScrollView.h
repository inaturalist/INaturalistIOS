//
//  PhotoScrollView.h
//  iNaturalist
//
//  Created by Alex Shepard on 9/9/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PhotoScrollView;

@protocol PhotoScrollViewDelegate <NSObject>
- (void)photoScrollView:(PhotoScrollView *)psv deletedIndex:(NSInteger)idx;
- (void)photoScrollView:(PhotoScrollView *)psv setDefaultIndex:(NSInteger)idx;
- (void)photoScrollViewAddPressed:(PhotoScrollView *)psv;
@end

@interface PhotoScrollView : UIView

@property (assign) id <PhotoScrollViewDelegate> delegate;
@property NSArray *photos;
@property UIButton *addButton;

@end
