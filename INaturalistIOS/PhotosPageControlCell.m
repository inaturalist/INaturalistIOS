//
//  PhotosPageControlCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/18/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>

#import "PhotosPageControlCell.h"

@implementation PhotosPageControlCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse {
    [self.iv sd_cancelCurrentImageLoad];
    self.pageControl.currentPage = 0;
}

@end
