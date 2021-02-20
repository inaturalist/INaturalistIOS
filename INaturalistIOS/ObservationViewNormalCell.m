//
//  ObservationViewCell.m
//  iNaturalist
//
//  Created by Eldad Ohana on 7/2/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

@import FontAwesomeKit;
@import UIColor_HTMLColors;

#import "ObservationViewNormalCell.h"
#import "UIColor+INaturalist.h"

@implementation ObservationViewNormalCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    // clear potentially italicized fonts
    self.titleLabel.font = [UIFont systemFontOfSize:self.titleLabel.font.pointSize];
}

@end
