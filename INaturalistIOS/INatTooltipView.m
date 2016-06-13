//
//  INatTooltipView.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/31/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "INatTooltipView.h"

@interface JDFTooltipView ()
- (CGRect)tooltipFrameForArrowPoint:(CGPoint)point width:(CGFloat)width labelFrame:(CGRect)labelFrame arrowDirection:(JDFTooltipViewArrowDirection)arrowDirection hostViewSize:(CGSize)hostViewSize;
@end

@implementation INatTooltipView

- (CGRect)tooltipFrameForArrowPoint:(CGPoint)point width:(CGFloat)width labelFrame:(CGRect)labelFrame arrowDirection:(JDFTooltipViewArrowDirection)arrowDirection hostViewSize:(CGSize)hostViewSize
{
    CGRect frame = [super tooltipFrameForArrowPoint:point width:width labelFrame:labelFrame arrowDirection:arrowDirection hostViewSize:hostViewSize];
    
    if (self.shouldCenter) {
        frame.origin.x = (hostViewSize.width - (point.x + width) + point.x) / 2;
    }
    
    return frame;
}
@end
