//
//  ObsCameraOverlay.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/17/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonIcons.h>

#import "ObsCameraOverlay.h"
#import "UIColor+ExploreColors.h"

@interface ObsCameraOverlay () {
    NSAttributedString *flashOn, *flashOff, *flashAuto;
}
@end

@implementation ObsCameraOverlay

- (void)configureFlashForMode:(UIImagePickerControllerCameraFlashMode)mode {
    if (mode == UIImagePickerControllerCameraFlashModeAuto)
        [self.flash setAttributedTitle:flashAuto forState:UIControlStateNormal];
    else if (mode == UIImagePickerControllerCameraFlashModeOff)
        [self.flash setAttributedTitle:flashOff forState:UIControlStateNormal];
    else if (mode == UIImagePickerControllerCameraFlashModeOn)
        [self.flash setAttributedTitle:flashOn forState:UIControlStateNormal];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        flashOn = ({
            FAKIcon *flash = [FAKIonIcons ios7BoltIconWithSize:30.0f];
            [flash addAttribute:NSForegroundColorAttributeName value:[UIColor inatGreen]];
            NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithAttributedString:flash.attributedString];
            
            [str appendAttributedString:[[NSAttributedString alloc] initWithString:@"   On"
                                                                        attributes:@{
                                                                                     NSForegroundColorAttributeName: [UIColor inatGreen],
                                                                                     NSFontAttributeName: [UIFont systemFontOfSize:14.0f],
                                                                                     NSBaselineOffsetAttributeName: @(5)
                                                                                     }]];
            str;
        });
        
        flashOff = ({
            FAKIcon *flash = [FAKIonIcons ios7BoltIconWithSize:30.0f];
            [flash addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
            NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithAttributedString:flash.attributedString];
            
            [str appendAttributedString:[[NSAttributedString alloc] initWithString:@"   Off"
                                                                        attributes:@{
                                                                                     NSForegroundColorAttributeName: [UIColor whiteColor],
                                                                                     NSFontAttributeName: [UIFont systemFontOfSize:14.0f],
                                                                                     NSBaselineOffsetAttributeName: @(5)
                                                                                     }]];

            str;
        });

        flashAuto = ({
            FAKIcon *flash = [FAKIonIcons ios7BoltIconWithSize:30.0f];
            [flash addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
            NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithAttributedString:flash.attributedString];
            
            [str appendAttributedString:[[NSAttributedString alloc] initWithString:@"   Auto"
                                                                        attributes:@{
                                                                                     NSForegroundColorAttributeName: [UIColor whiteColor],
                                                                                     NSFontAttributeName: [UIFont systemFontOfSize:14.0f],
                                                                                     NSBaselineOffsetAttributeName: @(5)
                                                                                     }]];

            str;
        });

        
        
        self.backgroundColor = [UIColor clearColor];
        
        self.close = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            button.frame = CGRectZero;
            button.backgroundColor = [UIColor blackColor];
            button.tintColor = [UIColor whiteColor];
            button.titleLabel.textAlignment = NSTextAlignmentLeft;
            FAKIcon *close = [FAKIonIcons ios7CloseEmptyIconWithSize:35.0f];
            [close addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
            [button setAttributedTitle:close.attributedString forState:UIControlStateNormal];
            button;
        });
        [self addSubview:self.close];
        
        self.camera = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            button.frame = CGRectZero;
            button.backgroundColor = [UIColor blackColor];
            button.tintColor = [UIColor whiteColor];
            button.titleLabel.textAlignment = NSTextAlignmentCenter;

            FAKIcon *camera = [FAKIonIcons ios7ReverseCameraOutlineIconWithSize:30.0f];
            [camera addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
            [button setAttributedTitle:camera.attributedString forState:UIControlStateNormal];
            button;
        });
        [self addSubview:self.camera];
        
        self.flash = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            button.frame = CGRectZero;
            button.backgroundColor = [UIColor blackColor];
            button.tintColor = [UIColor whiteColor];
            button.titleLabel.textAlignment = NSTextAlignmentRight;

            button;
        });
        [self addSubview:self.flash];
        
        self.noPhoto = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            button.frame = CGRectZero;
            button.backgroundColor = [UIColor blackColor];
            button.tintColor = [UIColor whiteColor];
            button.titleLabel.numberOfLines = 2;
            button.titleLabel.textAlignment = NSTextAlignmentCenter;
            [button setTitle:@"NO\nPHOTO" forState:UIControlStateNormal];
            button;
        });
        [self addSubview:self.noPhoto];
        
        self.shutter = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            button.frame = CGRectZero;
            button.backgroundColor = [UIColor blackColor];
            
            FAKIcon *circleIcon = [FAKIonIcons ios7CircleFilledIconWithSize:75.0f];
            [circleIcon addAttribute:NSForegroundColorAttributeName value:[UIColor inatGreen]];
            FAKIcon *circleOutline = [FAKIonIcons ios7CircleOutlineIconWithSize:75.0f];
            [circleOutline addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
            UIImage *shutterImage = [[UIImage imageWithStackedIcons:@[ circleIcon, circleOutline ] imageSize:CGSizeMake(75.0f, 75.0f)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            [button setImage:shutterImage
                    forState:UIControlStateNormal];
            button;
        });
        [self addSubview:self.shutter];
        
        self.library = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            button.frame = CGRectZero;
            button.tintColor = [UIColor whiteColor];
            button.backgroundColor = [UIColor blackColor];
            FAKIcon *libIcon = [FAKIonIcons imagesIconWithSize:45.0f];
            [button setAttributedTitle:libIcon.attributedString forState:UIControlStateNormal];
            button;
        });
        [self addSubview:self.library];
        
        NSDictionary *views = @{
                                @"close": self.close,
                                @"camera": self.camera,
                                @"flash": self.flash,
                                @"noPhoto": self.noPhoto,
                                @"shutter": self.shutter,
                                @"library": self.library,
                                };
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[close(==50)]"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[flash(==60)]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[camera(==50)]"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.camera
                                                         attribute:NSLayoutAttributeCenterX
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterX
                                                        multiplier:1.0f
                                                          constant:0.0f]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[noPhoto(==100)]"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[library(==100)]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[shutter(==100)]"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.shutter
                                                         attribute:NSLayoutAttributeCenterX
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterX
                                                        multiplier:1.0f
                                                          constant:0.0f]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[close(==40)]"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[flash(==40)]"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[camera(==40)]"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[noPhoto(==80)]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[library(==80)]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[shutter(==80)]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];

        
    }
    
    return self;
}


@end
