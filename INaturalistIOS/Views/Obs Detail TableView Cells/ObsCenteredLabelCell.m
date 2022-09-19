//
//  ObsSingleButtonCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 12/17/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import "ObsCenteredLabelCell.h"

@implementation ObsCenteredLabelCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.centeredLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.frame = CGRectZero;
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textAlignment = NSTextAlignmentCenter;
            
            label;
        });
        [self.contentView addSubview:self.centeredLabel];
        
        NSDictionary *views = @{ @"label": self.centeredLabel };
        
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[label]-|"
                                                                                 options:0
                                                                                 metrics:0
                                                                                   views:views]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[label]-0-|"
                                                                                 options:0
                                                                                 metrics:0
                                                                                   views:views]];
    }
    
    return self;
}

@end
