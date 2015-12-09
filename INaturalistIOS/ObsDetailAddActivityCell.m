//
//  ObsDetailAddActivityCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 12/8/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import "ObsDetailAddActivityCell.h"
#import "UIColor+INaturalist.h"

@implementation ObsDetailAddActivityCell

- (void)awakeFromNib {
    // Initialization code
    
    self.commentButton.backgroundColor = [UIColor inatTint];
    self.commentButton.layer.cornerRadius = 15.0f;
    self.commentButton.clipsToBounds = YES;
    
    self.suggestIDButton.backgroundColor = [UIColor inatTint];
    self.suggestIDButton.layer.cornerRadius = 15.0f;
    self.suggestIDButton.clipsToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
