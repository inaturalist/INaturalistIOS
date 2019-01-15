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
#import "UIView+UIViewHelpers.h"

@interface ObsCameraOverlay () {
    NSAttributedString *flashOn, *flashOff, *flashAuto;
}
@end

@implementation ObsCameraOverlay

- (void)configureFlashForMode:(UIImagePickerControllerCameraFlashMode)mode {
    if (mode == UIImagePickerControllerCameraFlashModeAuto) {
        [self.flash setAttributedTitle:flashAuto forState:UIControlStateNormal];
        self.flash.accessibilityLabel = NSLocalizedString(@"Change Flash Toggle. Current state is Auto",
                                                          @"accessibility label for flash button when mode is auto");
    } else if (mode == UIImagePickerControllerCameraFlashModeOff) {
        [self.flash setAttributedTitle:flashOff forState:UIControlStateNormal];
        self.flash.accessibilityLabel = NSLocalizedString(@"Change Flash Toggle. Current state is Off",
                                                          @"accessibility label for flash button when mode is off");
    } else if (mode == UIImagePickerControllerCameraFlashModeOn) {
        [self.flash setAttributedTitle:flashOn forState:UIControlStateNormal];
        self.flash.accessibilityLabel = NSLocalizedString(@"Change Flash Toggle. Current state is On",
                                                          @"accessibility label for flash button when mode is on");
    }
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        flashOn = ({
            FAKIcon *flash = [FAKIonIcons iosBoltIconWithSize:30.0f];
            [flash addAttribute:NSForegroundColorAttributeName value:[UIColor inatGreen]];
            NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithAttributedString:flash.attributedString];
            
            NSString *on = NSLocalizedString(@"On", @"On state for flash button in the camera. Will be padded to sit beside a flash/bolt icon.");
            [str appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"   %@", on]
                                                                        attributes:@{
                                                                                     NSForegroundColorAttributeName: [UIColor inatGreen],
                                                                                     NSFontAttributeName: [UIFont systemFontOfSize:14.0f],
                                                                                     NSBaselineOffsetAttributeName: @(5)
                                                                                     }]];
            str;
        });
        
        flashOff = ({
            FAKIcon *flash = [FAKIonIcons iosBoltIconWithSize:30.0f];
            [flash addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
            NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithAttributedString:flash.attributedString];
            
            NSString *off = NSLocalizedString(@"Off", @"Off state for flash button in the camera. Will be padded to sit beside a flash/bolt icon.");
            [str appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"   %@", off]
                                                                        attributes:@{
                                                                                     NSForegroundColorAttributeName: [UIColor whiteColor],
                                                                                     NSFontAttributeName: [UIFont systemFontOfSize:14.0f],
                                                                                     NSBaselineOffsetAttributeName: @(5)
                                                                                     }]];

            str;
        });

        flashAuto = ({
            FAKIcon *flash = [FAKIonIcons iosBoltIconWithSize:30.0f];
            [flash addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
            NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithAttributedString:flash.attributedString];
            
            NSString *automatic = NSLocalizedString(@"Auto", @"Auto state for flash button in the camera. Will be padded to sit beside a flash/bolt icon.");
            [str appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"   %@", automatic]
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
            button.accessibilityLabel = NSLocalizedString(@"Close Camera",
                                                          @"accessibility label for close camera button");
            button.translatesAutoresizingMaskIntoConstraints = NO;
            button.frame = CGRectZero;
            button.backgroundColor = [UIColor blackColor];
            button.tintColor = [UIColor whiteColor];
            button.titleLabel.textAlignment = NSTextAlignmentLeft;
            FAKIcon *close = [FAKIonIcons iosCloseEmptyIconWithSize:35.0f];
            [close addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
            [button setAttributedTitle:close.attributedString forState:UIControlStateNormal];
            button;
        });
        [self addSubview:self.close];
        
        self.camera = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.accessibilityLabel = NSLocalizedString(@"Reverse Camera",
                                                          @"accessibility label for reverse/switch camera button");
            button.translatesAutoresizingMaskIntoConstraints = NO;
            button.frame = CGRectZero;
            button.backgroundColor = [UIColor blackColor];
            button.tintColor = [UIColor whiteColor];
            button.titleLabel.textAlignment = NSTextAlignmentCenter;

            FAKIcon *camera = [FAKIonIcons iosReverseCameraOutlineIconWithSize:30.0f];
            [camera addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
            [button setAttributedTitle:camera.attributedString forState:UIControlStateNormal];
            button;
        });
        [self addSubview:self.camera];
        
        self.flash = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.accessibilityLabel = NSLocalizedString(@"Change Flash",
                                                          @"accessibility label for change flash button");
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
            button.accessibilityLabel = NSLocalizedString(@"No Photo",
                                                          @"accessibility label for no photo button");
            button.translatesAutoresizingMaskIntoConstraints = NO;
            button.frame = CGRectZero;
            button.backgroundColor = [UIColor blackColor];
            button.tintColor = [UIColor whiteColor];
            button.titleLabel.numberOfLines = 2;
            button.titleLabel.textAlignment = NSTextAlignmentCenter;
            [button setTitle:NSLocalizedString(@"NO\nPHOTO", @"Title for no photo button in the camera when making a new observation. Can support two very short lines of text.")
                    forState:UIControlStateNormal];
            button;
        });
        [self addSubview:self.noPhoto];
        
        self.shutter = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.accessibilityLabel = NSLocalizedString(@"Camera Shutter",
                                                          @"accessibility label for camera shutter button");
            button.translatesAutoresizingMaskIntoConstraints = NO;
            button.frame = CGRectZero;
            button.backgroundColor = [UIColor blackColor];
            
            FAKIcon *circleIcon = [FAKIonIcons iosCircleFilledIconWithSize:75.0f];
            [circleIcon addAttribute:NSForegroundColorAttributeName value:[UIColor inatGreen]];
            FAKIcon *circleOutline = [FAKIonIcons iosCircleOutlineIconWithSize:75.0f];
            [circleOutline addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
            UIImage *shutterImage = [[UIImage imageWithStackedIcons:@[ circleIcon, circleOutline ] imageSize:CGSizeMake(75.0f, 75.0f)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            [button setImage:shutterImage
                    forState:UIControlStateNormal];
            button;
        });
        [self addSubview:self.shutter];
        
        self.library = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.accessibilityLabel = NSLocalizedString(@"Pick from Library",
                                                          @"accessibility label for pick from library button");
            button.translatesAutoresizingMaskIntoConstraints = NO;
            button.frame = CGRectZero;
            button.tintColor = [UIColor whiteColor];
            button.backgroundColor = [UIColor blackColor];
            FAKIcon *libIcon = [FAKIonIcons imagesIconWithSize:45.0f];
            [button setAttributedTitle:libIcon.attributedString forState:UIControlStateNormal];
            button;
        });
        [self addSubview:self.library];
                
        UILayoutGuide *safeGuide = [self inat_safeLayoutGuide];

        // horizontal
        [self.close.leadingAnchor constraintEqualToAnchor:safeGuide.leadingAnchor].active = YES;
        [self.camera.centerXAnchor constraintEqualToAnchor:safeGuide.centerXAnchor].active = YES;
        [self.flash.trailingAnchor constraintEqualToAnchor:safeGuide.trailingAnchor].active = YES;
        [self.close.widthAnchor constraintEqualToConstant:50.0f].active = YES;
        [self.flash.widthAnchor constraintEqualToConstant:60.0f].active = YES;
        [self.camera.widthAnchor constraintEqualToConstant:50.0f].active = YES;
        
        [self.noPhoto.leadingAnchor constraintEqualToAnchor:safeGuide.leadingAnchor].active = YES;
        [self.shutter.centerXAnchor constraintEqualToAnchor:safeGuide.centerXAnchor].active = YES;
        [self.library.trailingAnchor constraintEqualToAnchor:safeGuide.trailingAnchor].active = YES;
        [self.noPhoto.widthAnchor constraintEqualToConstant:100.0f].active = YES;
        [self.shutter.widthAnchor constraintEqualToConstant:100.0f].active = YES;
        [self.library.widthAnchor constraintEqualToConstant:100.0f].active = YES;
        
        // vertical
        [self.close.topAnchor constraintEqualToAnchor:safeGuide.topAnchor].active = YES;
        [self.camera.topAnchor constraintEqualToAnchor:safeGuide.topAnchor].active = YES;
        [self.flash.topAnchor constraintEqualToAnchor:safeGuide.topAnchor].active = YES;
        [self.close.heightAnchor constraintEqualToConstant:40.0f].active = YES;
        [self.flash.heightAnchor constraintEqualToConstant:40.0f].active = YES;
        [self.camera.heightAnchor constraintEqualToConstant:40.0f].active = YES;

        [self.noPhoto.bottomAnchor constraintEqualToAnchor:safeGuide.bottomAnchor].active = YES;
        [self.shutter.bottomAnchor constraintEqualToAnchor:safeGuide.bottomAnchor].active = YES;
        [self.library.bottomAnchor constraintEqualToAnchor:safeGuide.bottomAnchor].active = YES;
        [self.noPhoto.heightAnchor constraintEqualToConstant:80.0f].active = YES;
        [self.shutter.heightAnchor constraintEqualToConstant:80.0f].active = YES;
        [self.library.heightAnchor constraintEqualToConstant:80.0f].active = YES;
    }
    
    return self;
}


@end
