//
//  ObsDetailActivityBodyCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 12/9/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import "ObsDetailActivityBodyCell.h"

@implementation ObsDetailActivityBodyCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // Initialization code
    self.bodyTextView.dataDetectorTypes = UIDataDetectorTypeAll;
    
    // remove the text container interior padding
    self.bodyTextView.textContainer.lineFragmentPadding = 0;
    self.bodyTextView.textContainerInset = UIEdgeInsetsZero;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse {
    self.bodyTextView.text = nil;
}

@end
