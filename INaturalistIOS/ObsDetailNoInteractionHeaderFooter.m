//
//  ObsDetailNoInteractionCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 12/29/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import "ObsDetailNoInteractionHeaderFooter.h"

@implementation ObsDetailNoInteractionHeaderFooter

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithReuseIdentifier:reuseIdentifier]) {
        
        self.noInteractionLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textAlignment = NSTextAlignmentCenter;
            label.numberOfLines = 0;
            
            label.textColor = [UIColor lightGrayColor];
            
            label;
        });
        [self addSubview:self.noInteractionLabel];
        
        
        NSDictionary *views = @{
                                @"noInteraction": self.noInteractionLabel,
                                };
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-30-[noInteraction]-30-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[noInteraction]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];

        
        
    }
    
    return self;
}

- (void)prepareForReuse {
    self.noInteractionLabel.text = nil;
}


@end
