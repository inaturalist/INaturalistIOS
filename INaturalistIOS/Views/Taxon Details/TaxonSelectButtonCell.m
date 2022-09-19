//
//  TaxonSelectButtonCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/25/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import "TaxonSelectButtonCell.h"

@implementation TaxonSelectButtonCell

- (void)awakeFromNib {
    [super awakeFromNib];

    self.button.clipsToBounds = YES;
    self.button.layer.cornerRadius = 22.0f;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
