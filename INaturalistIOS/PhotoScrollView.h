//
//  PhotoScrollView.h
//  iNaturalist
//
//  Created by Alex Shepard on 9/9/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PhotoScrollViewDelegate <NSObject>
- (void)deletePressedForIndex:(NSInteger)idx;
- (void)setDefaultPressedForIndex:(NSInteger)idx;
- (void)addPressed;
@end

@interface PhotoScrollView : UIView

@property (assign) id <PhotoScrollViewDelegate> delegate;
@property NSArray *photos;
@property UIButton *addButton;

@end
