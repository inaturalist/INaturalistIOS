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




@end
