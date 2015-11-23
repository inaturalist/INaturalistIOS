//
//  AddFaveCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/21/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import "AddFaveCell.h"
#import "UIColor+INaturalist.h"

@implementation AddFaveCell

- (void)awakeFromNib {
    self.addFaveButton.layer.cornerRadius = self.addFaveButton.bounds.size.height / 2.0f;
    self.addFaveButton.layer.borderColor = [UIColor inatTint].CGColor;
    self.addFaveButton.layer.borderWidth = 1.0f;

    self.addFaveButton.clipsToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
