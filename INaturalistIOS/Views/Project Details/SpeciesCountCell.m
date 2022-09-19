//
//  SpeciesCountCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

@import AFNetworking;
@import UIColor_HTMLColors;

#import "SpeciesCountCell.h"

@implementation SpeciesCountCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.taxonImageView.layer.cornerRadius = 1.0f;
    self.taxonImageView.clipsToBounds = YES;
    
    self.countLabel.text = @"";
    self.taxonNameLabel.text = @"";
    self.taxonImageView.image = nil;
    self.taxonSecondaryNameLabel.text = @"";
    self.taxonSecondaryNameLabel.textColor = [UIColor colorWithHexString:@"#8F8E94"];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.countLabel.text = @"";
    self.taxonNameLabel.text = @"";
    self.taxonImageView.image = nil;
    [self.taxonImageView cancelImageDownloadTask];
  
    self.taxonNameLabel.font = [UIFont systemFontOfSize:self.taxonNameLabel.font.pointSize];
    self.taxonSecondaryNameLabel.font = [UIFont systemFontOfSize:self.taxonSecondaryNameLabel.font.pointSize];
}

@end
