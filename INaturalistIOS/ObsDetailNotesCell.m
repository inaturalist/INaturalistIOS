//
//  ObsDetailNotesCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 12/10/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import "ObsDetailNotesCell.h"

@implementation ObsDetailNotesCell

- (void)awakeFromNib {
    // Initialization code
    self.notesTextView.contentMode = UIViewContentModeTop;
    
    self.notesTextView.textContainer.lineFragmentPadding = 0;
    self.notesTextView.textContainerInset = UIEdgeInsetsZero;    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
