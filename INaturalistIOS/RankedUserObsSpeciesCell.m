//
//  RankedUserObsSpeciesCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 4/5/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>

#import "RankedUserObsSpeciesCell.h"

@implementation RankedUserObsSpeciesCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.userImageView.layer.cornerRadius = self.userImageView.bounds.size.height / 2.0f;
    self.userImageView.clipsToBounds = YES;
    self.userImageView.layer.borderWidth = 1.0f;
    self.userImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.userImageView.backgroundColor = [UIColor lightGrayColor];
    self.userImageView.image = nil;

    self.observationsCountLabel.text = @"";
    self.speciesCountLabel.text = @"";
    self.userNameLabel.text = @"";
    self.rankLabel.text = @"";
}

- (void)prepareForReuse {
    self.userImageView.image = nil;
    [self.userImageView cancelImageRequestOperation];
    
    self.observationsCountLabel.text = @"";
    self.speciesCountLabel.text = @"";
    self.userNameLabel.text = @"";
    self.rankLabel.text = @"";
}

@end
