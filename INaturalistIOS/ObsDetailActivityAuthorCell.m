//
//  ObsDetailActivityAuthorCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 12/9/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>

#import "ObsDetailActivityAuthorCell.h"

@implementation ObsDetailActivityAuthorCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse {
    [self.authorImageView sd_cancelCurrentImageLoad];
    self.authorImageView.image = nil;
    self.authorNameLabel.text = nil;
    self.dateLabel.text = nil;
}

@end
