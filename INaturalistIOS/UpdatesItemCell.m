//
//  UpdatesItemCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/21/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>

#import "UpdatesItemCell.h"

@implementation UpdatesItemCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.profileImageView.layer.cornerRadius = 20.0f;
    self.profileImageView.clipsToBounds = YES;
    self.profileImageView.backgroundColor = [UIColor lightGrayColor];
    self.profileImageView.layer.borderWidth = 1.0f;
    self.profileImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    self.observationImageView.layer.cornerRadius = 1.0f;
    self.observationImageView.clipsToBounds = YES;
    
    // make the separator span the entire cell width
    self.preservesSuperviewLayoutMargins = NO;
    self.separatorInset = UIEdgeInsetsZero;
    self.layoutMargins = UIEdgeInsetsZero;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

}

- (void)prepareForReuse {
    [self.profileImageView cancelImageRequestOperation];
    [self.observationImageView cancelImageRequestOperation];
    self.profileImageView.image = nil;
    self.observationImageView.image = nil;
    self.updateTextLabel.text = nil;
    self.backgroundColor = [UIColor clearColor];
}

@end
