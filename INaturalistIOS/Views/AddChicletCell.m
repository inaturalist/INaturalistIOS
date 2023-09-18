//
//  AddChicletCell.m
//  
//
//  Created by Alex Shepard on 10/22/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import "AddChicletCell.h"
#import "INaturalist-Swift.h"

@implementation AddChicletCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIImageView *plusImageView = ({
            UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
            iv.translatesAutoresizingMaskIntoConstraints = NO;

            iv.layer.borderColor = [UIColor grayColor].CGColor;
            iv.layer.borderWidth = 1.0f;
            iv.tintColor = [UIColor grayColor];

            iv.image = [UIImage iconImageWithSystemName:@"plus" size:IconImageSizeSmall];
            iv.contentMode = UIViewContentModeCenter;

            iv;
        });
        [self.contentView addSubview:plusImageView];

        [plusImageView.heightAnchor constraintEqualToAnchor:plusImageView.widthAnchor].active = YES;
        [plusImageView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:9].active = YES;
        [plusImageView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-9].active = YES;
        [plusImageView.topAnchor constraintEqualToAnchor:self.topAnchor constant:9].active = YES;
    }
    

    return self;
}

@end
