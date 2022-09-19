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
    [super awakeFromNib];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.notesTextView.contentMode = UIViewContentModeCenter;
    
    // having a hard time vertically centering the notes text view text in the cell
    // without using autolayout
    self.notesTextView.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSDictionary *views = @{ @"textview": self.notesTextView, };
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-15-[textview]-15-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.notesTextView
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.0f
                                                      constant:0.0f]];
    
    // remove the text container interior padding
    self.notesTextView.textContainer.lineFragmentPadding = 0;
    self.notesTextView.textContainerInset = UIEdgeInsetsZero;    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
