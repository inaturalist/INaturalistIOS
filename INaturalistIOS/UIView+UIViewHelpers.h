//
//  UIView+FindFirstResponder.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/21/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (UIViewHelpers)
- (UIView *)findFirstResponder;
- (BOOL)findAndResignFirstResponder;
- (UIView *)descendentPassingTest:(BOOL (^)(UIView *))block;
@end
