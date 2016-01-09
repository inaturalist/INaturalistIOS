//
//  ObsDetailQualityDetailsFooter.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/8/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "ObsDetailQualityDetailsFooter.h"

@interface ObsDetailQualityDetailsFooter () {
    NSString *_dataQualityDetails;
}
@property UILabel *qualityDetailsLabel;
@end

@implementation ObsDetailQualityDetailsFooter

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithReuseIdentifier:reuseIdentifier]) {
        
        self.backgroundColor = [UIColor colorWithHexString:@"#dedee3"];
        
        self.qualityDetailsLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;

            label.font = [UIFont systemFontOfSize:15];
            label.textColor = [UIColor colorWithHexString:@"#5C5C5C"];
            label.numberOfLines = 0;
            label.textAlignment = NSTextAlignmentCenter;
            
            label;
        });
        [self addSubview:self.qualityDetailsLabel];
        
        UIView *bottomEdge = ({
            UIView *view = [UIView new];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            
            view.backgroundColor = [UIColor colorWithHexString:@"#c8c7cc"];
            
            view;
        });
        [self addSubview:bottomEdge];
        
        NSDictionary *views = @{
                                @"label": self.qualityDetailsLabel,
                                @"edge": bottomEdge,
                                };
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-15-[label]-15-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[label]-5-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[edge]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[edge(==0.5)]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];

    }
    
    return self;
}

- (NSString *)dataQualityDetails {
    return _dataQualityDetails;
}

- (void)setDataQualityDetails:(NSString *)dataQualityDetails {
    _dataQualityDetails = dataQualityDetails;
    
    self.qualityDetailsLabel.text = dataQualityDetails;
}

@end
