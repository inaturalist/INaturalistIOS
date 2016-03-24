//
//  ObserverCountCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>

#import "ObserverCountCell.h"

@implementation ObserverCountCell

- (void)awakeFromNib {
    self.observerImageView.layer.cornerRadius = self.observerImageView.bounds.size.height / 2.0f;
    self.observerImageView.clipsToBounds = YES;
    self.observerImageView.layer.borderWidth = 1.0f;
    self.observerImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    self.observerObservationsCountLabel.text = @"";
    self.observerNameLabel.text = @"";
    self.observerImageView.image = nil;
}

- (void)prepareForReuse {
    self.observerObservationsCountLabel.text = @"";
    self.observerNameLabel.text = @"";
    self.observerImageView.image = nil;
    [self.observerImageView sd_cancelCurrentImageLoad];
}

@end
