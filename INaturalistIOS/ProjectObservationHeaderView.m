//
//  ProjectObservationHeaderView.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/7/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import "UIColor-HTMLColors/UIColor+HTMLColors.h"

#import "ProjectObservationHeaderView.h"

@interface ProjectObservationHeaderView ()

@end

@implementation ProjectObservationHeaderView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.backgroundColor = [UIColor whiteColor];
    
    self.projectThumbnailImageView.layer.cornerRadius = 2.0f;
    self.projectThumbnailImageView.layer.borderColor = [UIColor colorWithHexString:@"#aaaaaa"].CGColor;
    self.projectThumbnailImageView.layer.borderWidth = 1.0f;
    self.projectThumbnailImageView.clipsToBounds = YES;
}

@end
