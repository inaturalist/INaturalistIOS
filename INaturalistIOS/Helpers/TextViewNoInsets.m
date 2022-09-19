//
//  TextViewNoInsets.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/21/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import "TextViewNoInsets.h"

@implementation TextViewNoInsets

- (void)layoutSubviews {
    [super layoutSubviews];
    [self removeInsets];
}

- (void)removeInsets {
    self.textContainerInset = UIEdgeInsetsZero;
    self.textContainer.lineFragmentPadding = 0.0f;
}

@end
