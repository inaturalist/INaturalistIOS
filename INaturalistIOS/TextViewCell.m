//
//  TextViewCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 9/4/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "TextViewCell.h"

@implementation TextViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.textView = ({
            UITextView *tv = [[UITextView alloc] initWithFrame:self.bounds];
            tv.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
            
            tv;
        });
        [self.contentView addSubview:self.textView];
    }
    
    return self;
}

@end
