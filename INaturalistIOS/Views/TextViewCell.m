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
            UITextView *tv = [[UITextView alloc] initWithFrame:CGRectMake(10, 5, self.bounds.size.width - 20, self.bounds.size.height -10)];
            tv.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
            
            tv.font = [UIFont systemFontOfSize:13];
            
            tv;
        });
        [self.contentView addSubview:self.textView];
    }
    
    return self;
}

@end
