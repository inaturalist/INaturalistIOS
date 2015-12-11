//
//  ObsFieldMultiCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/8/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import "UIColor-HTMLColors/UIColor+HTMLColors.h"

#import "ObsFieldSimpleValueCell.h"


@implementation ObsFieldSimpleValueCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        self.backgroundColor = [UIColor colorWithHexString:@"#f1f7e5"];
        self.indentationLevel = 3;
        
        self.fieldLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.numberOfLines = 0;
            label.textColor = [UIColor blackColor];
            
            label;
        });
        [self.contentView addSubview:self.fieldLabel];
        
        self.valueLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.numberOfLines = 0;
            label.textColor = [UIColor colorWithHexString:@"#848484"];
            label.textAlignment = NSTextAlignmentRight;
            
            label;
        });
        [self.contentView addSubview:self.valueLabel];
        
        NSDictionary *views = @{
                                @"field": self.fieldLabel,
                                @"value": self.valueLabel,
                                };
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[field]-[value]-|"
                                                                    options:0
                                                                    metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[field]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[value]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.valueLabel
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.contentView
                                                         attribute:NSLayoutAttributeWidth
                                                        multiplier:0.3f
                                                          constant:0.0f]];

    }
    
    return self;
}

@end
