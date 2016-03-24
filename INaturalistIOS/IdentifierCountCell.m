//
//  IdentifierCountCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>

#import "IdentifierCountCell.h"

@implementation IdentifierCountCell

- (void)awakeFromNib {
    self.identifierImageView.layer.cornerRadius = self.identifierImageView.bounds.size.height / 2.0f;
    self.identifierImageView.clipsToBounds = YES;
    self.identifierImageView.layer.borderWidth = 1.0f;
    self.identifierImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    self.identifierCountLabel.text = @"";
    self.identifierNameLabel.text = @"";
    self.identifierImageView.image = nil;
}

- (void)prepareForReuse {
    self.identifierCountLabel.text = @"";
    self.identifierNameLabel.text = @"";
    self.identifierImageView.image = nil;
    [self.identifierImageView sd_cancelCurrentImageLoad];
}

@end
