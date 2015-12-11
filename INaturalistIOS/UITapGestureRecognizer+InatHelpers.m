//
//  UITapGestureRecognizer+InatHelpers.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/26/15.
//

#import "UITapGestureRecognizer+InatHelpers.h"

@implementation UITapGestureRecognizer (InatHelpers)

// thank you @zekel: http://stackoverflow.com/a/29352519/1454875
- (BOOL)didTapAttributedTextInLabel:(UILabel *)label inRange:(NSRange)targetRange {
    
    CGSize labelSize = label.bounds.size;
    // create instances of NSLayoutManager, NSTextContainer and NSTextStorage
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeZero];
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:label.attributedText];
    
    // configure layoutManager and textStorage
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    
    // configure textContainer for the label
    textContainer.lineFragmentPadding = 0.0;
    textContainer.lineBreakMode = label.lineBreakMode;
    textContainer.maximumNumberOfLines = label.numberOfLines;
    textContainer.size = labelSize;
    
    // find the tapped character location and compare it to the specified range
    CGPoint locationOfTouchInLabel = [self locationInView:label];
    CGRect textBoundingBox = [layoutManager usedRectForTextContainer:textContainer];
    CGPoint textContainerOffset = CGPointMake((labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
                                              (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y);
    CGPoint locationOfTouchInTextContainer = CGPointMake(locationOfTouchInLabel.x - textContainerOffset.x,
                                                         locationOfTouchInLabel.y - textContainerOffset.y);
    NSInteger indexOfCharacter = [layoutManager characterIndexForPoint:locationOfTouchInTextContainer
                                                       inTextContainer:textContainer
                              fractionOfDistanceBetweenInsertionPoints:nil];
    if (NSLocationInRange(indexOfCharacter, targetRange)) {
        return YES;
    } else {
        return NO;
    }
}

@end
