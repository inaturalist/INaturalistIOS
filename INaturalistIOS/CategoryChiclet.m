//
//  CategoryChiclet.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/25/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "CategoryChiclet.h"

@implementation CategoryChiclet

+ (instancetype)buttonWithType:(UIButtonType)buttonType {
    CategoryChiclet *chiclet = [super buttonWithType:buttonType];
    if (chiclet) {
        chiclet.categoryImageView = ({
            UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
            iv.translatesAutoresizingMaskIntoConstraints = NO;
            
            iv.clipsToBounds = YES;
            
            iv;
        });
        [chiclet addSubview:chiclet.categoryImageView];
        
        chiclet.categoryLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textColor = [UIColor whiteColor];
            label.font = [UIFont fontWithName:@"HelveticaNeue" size:13.0f];
            label.textAlignment = NSTextAlignmentCenter;
            
            label.clipsToBounds = NO;
            
            label;
        });
        [chiclet addSubview:chiclet.categoryLabel];
        
        NSDictionary *views = @{
                                @"image": chiclet.categoryImageView,
                                @"label": chiclet.categoryLabel,
                                };
        
        [chiclet addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-10-[image]-10-|"
                                                                        options:0
                                                                        metrics:0
                                                                          views:views]];
        [chiclet addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-5-[label]-5-|"
                                                                        options:0
                                                                        metrics:0
                                                                          views:views]];
        [chiclet addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[image]"
                                                                        options:0
                                                                        metrics:0
                                                                          views:views]];
        [chiclet addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[label]-8-|"
                                                                        options:0
                                                                        metrics:0
                                                                          views:views]];



    }
    
    return chiclet;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
