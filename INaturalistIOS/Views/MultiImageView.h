//
//  MultiImageView.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/26/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MultiImageView : UIView

@property CGFloat borderWidth;
@property UIColor *borderColor;
@property UIColor *pieColor;
@property CGFloat pieBorderWidth;

@property (readonly) NSArray *imageViews;
@property (readonly) NSArray *progressViews;
@property (readonly) NSArray *alertViews;

@property NSInteger imageCount;

@end
