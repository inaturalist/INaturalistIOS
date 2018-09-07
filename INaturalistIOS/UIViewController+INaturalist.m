//
//  UIViewController+INaturalist.m
//  iNaturalist
//
//  Created by Alex Shepard on 9/7/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import "UIViewController+INaturalist.h"

@implementation UIViewController (INaturalist)

- (UILayoutGuide *)inat_safeLayoutGuide {
    UILayoutGuide *safeLayoutGuide = nil;
    if (@available(iOS 11.0, *)) {
        safeLayoutGuide = self.view.safeAreaLayoutGuide;
    } else {
        safeLayoutGuide = [[UILayoutGuide alloc] init];
        [self.view addLayoutGuide:safeLayoutGuide];
        [safeLayoutGuide.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
        [safeLayoutGuide.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
        [safeLayoutGuide.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor].active = YES;
        [safeLayoutGuide.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.topAnchor].active = YES;
    }
    return safeLayoutGuide;
}

@end
