//
//  RoundedButtonCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/25/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "RoundedButtonCell.h"

@implementation RoundedButtonCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        self.backgroundColor = [UIColor clearColor];
        
        self.roundedButton = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            
            button.frame = self.bounds;
            button.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
                        
            button;
        });
        [self addSubview:self.roundedButton];
    }
    return self;
}

- (void)layoutSubviews {
    self.roundedButton.layer.cornerRadius = self.roundedButton.bounds.size.height / 2.0f;
}

@end
