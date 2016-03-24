//
//  ObservationViewCellUploading.m
//  iNaturalist
//
//  Created by Alex Shepard on 9/29/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "ObservationViewUploadingCell.h"
#import "UIColor+INaturalist.h"

@implementation ObservationViewUploadingCell

// would be great to do all of this autolayout stuff in the storyboard, but that means migrating the whole storyboard to AutoLayout
- (void)awakeFromNib {
    self.progressView.progressTintColor = [UIColor inatTint];
    self.progressView.trackTintColor = [UIColor colorWithHexString:@"#C6DFA4"];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CATransform3D transform = CATransform3DMakeScale(1.0f, 5.0f, 1.0f);
    self.progressView.layer.transform = transform;
    
}

@end
