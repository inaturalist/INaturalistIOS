//
//  RefreshControl.m
//  iNaturalist
//
//  Created by Ryan Waggoner on 10/23/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import "RefreshControl.h"

@implementation RefreshControl {
    CGFloat topContentInset;
    BOOL topContentInsetSaved;
}

- (void)layoutSubviews {
    [super layoutSubviews];
	
    // getting containing scrollView
    UIScrollView *scrollView = (UIScrollView *)self.superview;
	
    // saving present top contentInset, because it can be changed by refresh control
    if (!topContentInsetSaved) {
        topContentInset = scrollView.contentInset.top;
        topContentInsetSaved = YES;
    }
	
    // saving own frame, that will be modified
    CGRect newFrame = self.frame;
	
    // if refresh control is fully or partially behind UINavigationBar
    if (scrollView.contentOffset.y + topContentInset > -newFrame.size.height) {
        // moving it with the rest of the content
        newFrame.origin.y = -newFrame.size.height;
		
		// if refresh control fully appeared
    } else {
        // keeping it at the same place
        newFrame.origin.y = scrollView.contentOffset.y + topContentInset;
    }
	
    // applying new frame to the refresh control
    self.frame = newFrame;
}

@end
