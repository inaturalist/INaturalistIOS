//
//  TaxonSuggestionCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 4/21/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import "TaxonSuggestionCell.h"
#import "UIColor+INaturalist.h"

@implementation TaxonSuggestionCell

- (void)awakeFromNib {
    [super awakeFromNib];

    self.image.clipsToBounds = YES;
    self.image.contentMode = UIViewContentModeScaleAspectFill;
    self.comment.textColor = [UIColor inatTint];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.primaryName.font = [UIFont systemFontOfSize:self.primaryName.font.pointSize];
    self.secondaryName.font = [UIFont systemFontOfSize:self.secondaryName.font.pointSize];
}

@end
