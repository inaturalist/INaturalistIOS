//
//  InsetLabel.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/22/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import "InsetLabel.h"

@implementation InsetLabel

- (void)drawTextInRect:(CGRect)rect {
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.insets)];
}

- (CGSize)intrinsicContentSize {
    CGSize size = [super intrinsicContentSize];
    size.width  += self.insets.left + self.insets.right;
    size.height += self.insets.top + self.insets.bottom;
    return size;
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize adjSize = [super sizeThatFits:size];
    adjSize.width  += self.insets.left + self.insets.right;
    adjSize.height += self.insets.top + self.insets.bottom;
    return adjSize;
}

@end
