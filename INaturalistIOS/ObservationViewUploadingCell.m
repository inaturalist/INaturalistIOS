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

- (void)awakeFromNib {
    [super awakeFromNib];
    
	self.progressBar.trackTintColor = [UIColor colorWithHexString:@"#C6DFA4"];
    self.progressBar.type = YLProgressBarTypeFlat;
    self.progressBar.behavior = YLProgressBarBehaviorWaiting;
    self.progressBar.progressTintColors = @[ [UIColor inatTint] ];
}

@end
