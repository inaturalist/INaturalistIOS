//
//  DejalOutsideKeyboardActivityView.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/30/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "DejalOutsideKeyboardActivityView.h"

@implementation DejalOutsideKeyboardActivityView

- (CGRect)enclosingFrame;
{
    CGRect frame = [super enclosingFrame];
    UIView *keyboardView = [[UIApplication sharedApplication] keyboardView];
    if (keyboardView) {
        frame = CGRectMake(frame.origin.x, 
                           frame.origin.y, 
                           frame.size.width, 
                           frame.size.height - keyboardView.frame.size.height + 50);
    }
    return frame;
}

@end
