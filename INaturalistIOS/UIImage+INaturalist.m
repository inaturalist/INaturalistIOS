//
//  UIImage+INaturalist.m
//  iNaturalist
//
//  Created by Alex Shepard on 6/15/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonIcons.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "UIImage+INaturalist.h"


@implementation UIImage (INaturalist)

+ (instancetype)inat_defaultGuideImage {
    static UIImage *defaultGuideImage;
    if (!defaultGuideImage) {
        defaultGuideImage = ({
            FAKIcon *guideIcon = [FAKIonIcons iosBookOutlineIconWithSize:40];
            [guideIcon addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#8e8e93"]];
            [guideIcon imageWithSize:CGSizeMake(40, 40)];
        });
    }
    return defaultGuideImage;
}

+ (instancetype)inat_defaultProjectImage {
    static UIImage *defaultProjectImage;
    if (!defaultProjectImage) {
        defaultProjectImage = ({
            FAKIcon *projectIcon = [FAKIonIcons iosBriefcaseOutlineIconWithSize:80];
            [projectIcon addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#8e8e93"]];
            [projectIcon imageWithSize:CGSizeMake(80, 80)];
        });
    }
    return defaultProjectImage;
}

+ (instancetype)inat_defaultUserImage {
    static UIImage *defaultUserImage;
    if (!defaultUserImage) {
        defaultUserImage = ({
            FAKIcon *person = [FAKIonIcons iosPersonIconWithSize:40];
            [person addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
            FAKIcon *circle = [FAKIonIcons recordIconWithSize:60];
            [circle addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor]];
            [UIImage imageWithStackedIcons:@[ circle, person ] imageSize:CGSizeMake(60, 60)];
        });
    }
    return defaultUserImage;
}

/*
 from
 https://stackoverflow.com/questions/37832794/how-to-set-border-on-image-in-swift-not-on-uiimageview
 */
- (instancetype)inat_imageByAddingBorderWidth:(CGFloat)borderWidth radius:(CGFloat)radius color:(UIColor *)color {
    CALayer *imageLayer = [CALayer layer];
    imageLayer.frame = CGRectMake(0, 0, self.size.width, self.size.height);
    imageLayer.contents = (id)self.CGImage;
    
    imageLayer.masksToBounds = YES;
    imageLayer.cornerRadius = radius;
    imageLayer.borderColor = color.CGColor;
    imageLayer.borderWidth = borderWidth;
    
    UIGraphicsBeginImageContext(self.size);
    [imageLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *roundedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return roundedImage;
}



@end
