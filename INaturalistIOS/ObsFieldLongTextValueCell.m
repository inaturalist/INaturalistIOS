//
//  ObsFieldTextCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/8/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import "UIColor-HTMLColors/UIColor+HTMLColors.h"

#import "ObsFieldLongTextValueCell.h"

@implementation ObsFieldLongTextValueCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        self.backgroundColor = [UIColor colorWithHexString:@"#f1f7e5"];
        
        self.fieldLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.numberOfLines = 0;
            
            label;
        });
        [self.contentView addSubview:self.fieldLabel];
        
        self.textField = ({
            UITextField *tf = [[UITextField alloc] initWithFrame:CGRectZero];
            tf.translatesAutoresizingMaskIntoConstraints = NO;
            
            tf.font = [UIFont systemFontOfSize:14.0f];
            tf.placeholder = NSLocalizedString(@"Your response here", @"Placeholder for free text observation field value");
            
            tf;
        });
        [self.contentView addSubview:self.textField];
        
        NSDictionary *views = @{
                                @"field" : self.textField,
                                @"label": self.fieldLabel,
                                };
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[label]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[field]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[label]-[field]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];

        
    }
    
    return self;
}

@end
