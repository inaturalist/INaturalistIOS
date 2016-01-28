//
//  ProjectPostCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/20/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "NewsItemCell.h"
#import "UIColor+INaturalist.h"

@implementation NewsItemCell


- (void)awakeFromNib {
    self.newsCategoryImageView.layer.cornerRadius = 0.5f;
    self.newsCategoryImageView.layer.borderWidth = 1.0f;
    self.newsCategoryImageView.layer.borderColor = [UIColor colorWithHexString:@"#C8C7CC"].CGColor;
}

- (void)prepareForReuse {
    [self.newsCategoryImageView sd_cancelCurrentImageLoad];
    self.newsCategoryImageView.image = nil;
    [self.postImageView sd_cancelCurrentImageLoad];
    self.postImageView.image = nil;
    
    self.newsCategoryTitle.text = nil;
    self.postedAt.text = nil;
    self.postBody.text = nil;
    self.postTitle.text = nil;
}

@end
