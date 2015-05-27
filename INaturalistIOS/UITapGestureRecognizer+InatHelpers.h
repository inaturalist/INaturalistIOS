//
//  UITapGestureRecognizer+InatHelpers.h
//  iNaturalist
//
//  Created by Alex Shepard on 5/26/15.
//

#import <UIKit/UIKit.h>

@interface UITapGestureRecognizer (InatHelpers)

- (BOOL)didTapAttributedTextInLabel:(UILabel *)label inRange:(NSRange)targetRange;

@end
