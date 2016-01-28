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

#import "ProjectPostCell.h"
#import "UIColor+INaturalist.h"

@implementation ProjectPostCell


- (void)awakeFromNib {
    self.projectImageView.layer.cornerRadius = 0.5f;
    self.projectImageView.layer.borderWidth = 1.0f;
    self.projectImageView.layer.borderColor = [UIColor colorWithHexString:@"#C8C7CC"].CGColor;
}

- (void)prepareForReuse {
    [self.projectImageView sd_cancelCurrentImageLoad];
    self.projectImageView.image = nil;
    [self.postImageView sd_cancelCurrentImageLoad];
    self.postImageView.image = nil;
    
    self.projectName.text = nil;
    self.postedAt.text = nil;
    self.postBody.text = nil;
    self.postTitle.text = nil;
}

@end
