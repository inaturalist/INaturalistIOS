//
//  MeHeaderView.h
//  iNaturalist
//
//  Created by Alex Shepard on 3/11/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SplitTextButton.h"

@interface MeHeaderView : UIView

@property UIButton *iconButton;
@property UILabel *obsCountLabel;
@property UIActivityIndicatorView *uploadingSpinner;

- (void)startAnimatingUpload;
- (void)stopAnimatingUpload;

@end
