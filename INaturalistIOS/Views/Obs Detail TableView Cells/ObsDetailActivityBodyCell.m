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

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.bodyTextView.text = nil;
}

@end
