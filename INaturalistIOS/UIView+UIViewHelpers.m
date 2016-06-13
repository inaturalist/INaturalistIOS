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
                                   
@end
