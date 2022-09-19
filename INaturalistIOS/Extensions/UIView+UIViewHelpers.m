//
//  UIView+FindFirstResponder.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/21/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "UIView+UIViewHelpers.h"

@implementation UIView (UIViewHelpers)
- (UIView *)findFirstResponder
{
    if (self.isFirstResponder) {
        return self;
    }
    UIView *view;
    for (UIView *subView in self.subviews) {
        view = [subView findFirstResponder];
        if (view) return view;
    }
    return nil;
}
- (BOOL)findAndResignFirstResponder
{
    UIView *view = [self findFirstResponder];
    if (view) {
        [view resignFirstResponder];
        return YES;
    }
    return NO;
}

- (UIView *)descendentPassingTest:(BOOL (^)(UIView *))block
{
    UIView *match;
    for (UIView *child in self.subviews) {
        if (block(child)) {
            match = child;
        } else {
            match = [child descendentPassingTest:block];
        }
        if (match) {
            return match;
        }
    }
    return nil;
}

- (UILayoutGuide *)inat_safeLayoutGuide {
    UILayoutGuide *safeLayoutGuide = nil;
    if (@available(iOS 11.0, *)) {
        safeLayoutGuide = self.safeAreaLayoutGuide;
    } else {
        safeLayoutGuide = [[UILayoutGuide alloc] init];
        [self addLayoutGuide:safeLayoutGuide];
        [safeLayoutGuide.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
        [safeLayoutGuide.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
        [safeLayoutGuide.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
        [safeLayoutGuide.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
    }
    return safeLayoutGuide;
}

@end
