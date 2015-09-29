//
//  ObservationAlertHeader.m
//  iNaturalist
//
//  Created by Alex Shepard on 9/29/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "ObservationValidationErrorView.h"

@interface ObservationValidationErrorView ()
@property UILabel *errorLabel;
@end

@implementation ObservationValidationErrorView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = [UIColor colorWithHexString:@"#F4D4DB"];
        
        self.errorLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, frame.size.width - 10, frame.size.height - 10)];
            label.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
            
            label.numberOfLines = 0;
            label.textColor = [UIColor colorWithHexString:@"#BF373E"];
            label.textAlignment = NSTextAlignmentCenter;
            
            label;
        });
        [self addSubview:self.errorLabel];

    }
    
    return self;
}

- (void)setValidationError:(NSString *)validationError {
    self.errorLabel.text = validationError;
}

- (NSString *)validationError {
    return self.errorLabel.text;
}


@end
