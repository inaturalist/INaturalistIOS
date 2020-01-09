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

@property IBOutlet UIButton *iconButton;
@property IBOutlet UILabel *obsCountLabel;
@property IBOutlet UIActivityIndicatorView *uploadingSpinner;

@property IBOutlet UIButton *inatYiRButton;
@property IBOutlet UIButton *meYiRButton;

- (void)startAnimatingUpload;
- (void)stopAnimatingUpload;

@end
