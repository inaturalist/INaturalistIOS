//
//  RestrictedCollectionHeader.m
//  iNaturalist
//
//  Created by Alex Shepard on 12/1/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonIcons.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "RestrictedCollectionHeader.h"
#import "UIColor+ExploreColors.h"

@implementation RestrictedCollectionHeader

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = [UIColor colorWithHexString:@"#f0f0f0"];
        
        self.titleLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 0,
                                                                       frame.size.width - 15 - 30, // room for indent and clearbutton
                                                                       frame.size.height)];
            label.font = [UIFont systemFontOfSize:12.0f];
            label.tag = 0x1;
            label.backgroundColor = [UIColor clearColor];
            label.textColor = [UIColor blackColor];
            label;
        });
        [self addSubview:self.titleLabel];

        self.clearButton = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            
            FAKIcon *clear = [FAKIonIcons ios7CloseEmptyIconWithSize:30.0f];
            [clear addAttribute:NSForegroundColorAttributeName value:[UIColor inatGreen]];
            [button setAttributedTitle:clear.attributedString forState:UIControlStateNormal];
            
            button.frame = CGRectMake(frame.size.width - 30 - 15,        // room for indent and button
                                      0, 30, frame.size.height);
            
            button;
        });
        [self addSubview:self.clearButton];
    }
    
    return self;
}

@end
