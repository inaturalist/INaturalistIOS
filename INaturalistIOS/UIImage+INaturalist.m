//
//  UIImage+INaturalist.m
//  iNaturalist
//
//  Created by Alex Shepard on 6/15/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonIcons.h>

#import "UIImage+INaturalist.h"


@implementation UIImage (INaturalist)

+ (instancetype)inat_defaultGuideImage {
    static UIImage *defaultGuideImage;
    if (!defaultGuideImage) {
        defaultGuideImage = ({
            FAKIcon *guideIcon = [FAKIonIcons iosBookOutlineIconWithSize:40];
            [guideIcon addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor]];
            [guideIcon imageWithSize:CGSizeMake(40, 40)];
        });
    }
    return defaultGuideImage;
}

+ (instancetype)inat_defaultProjectImage {
    static UIImage *defaultProjectImage;
    if (!defaultProjectImage) {
        defaultProjectImage = ({
            FAKIcon *projectIcon = [FAKIonIcons iosBriefcaseOutlineIconWithSize:40];
            [projectIcon addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor]];
            [projectIcon imageWithSize:CGSizeMake(40, 40)];
        });
    }
    return defaultProjectImage;
}


@end
