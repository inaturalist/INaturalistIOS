//
//  MultiImageView.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/26/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <M13ProgressSuite/M13ProgressViewPie.h>
#import <FontAwesomeKit/FAKIonIcons.h>

#import "MultiImageView.h"
#import "UIColor+INaturalist.h"

@interface MultiImageView () {
    CGFloat _borderWidth;
    UIColor *_borderColor;
    CGFloat _pieBorderWidth;
    UIColor *_pieColor;
    NSInteger _imageCount;

    
    UIImageView *one;
    UIImageView *two;
    UIImageView *three;
    UIImageView *four;
    
    M13ProgressViewPie *onePie;
    M13ProgressViewPie *twoPie;
    M13ProgressViewPie *threePie;
    M13ProgressViewPie *fourPie;

    UIImageView *oneAlert;
    UIImageView *twoAlert;
    UIImageView *threeAlert;
    UIImageView *fourAlert;

}
@end

@implementation MultiImageView

- (NSArray *)progressViews {
    return @[ onePie, twoPie, threePie, fourPie];
}

- (NSArray *)imageViews {
    return @[ one, two, three, four ];
}

- (NSArray *)alertImageViews {
    return @[ oneAlert, twoAlert, threeAlert, fourAlert ];
}

- (void)setImageCount:(NSInteger)imageCount {
    _imageCount = imageCount;
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf setNeedsLayout];
    });
}

- (NSInteger)imageCount {
    return _imageCount;
}

- (CGFloat)pieBorderWidth {
    return _pieBorderWidth;
}

- (void)setPieBorderWidth:(CGFloat)pieBorderWidth {
    if (_pieBorderWidth == pieBorderWidth)
        return;
    
    _pieBorderWidth = pieBorderWidth;
    
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf setNeedsLayout];
    });
}

- (UIColor *)pieColor {
    return _pieColor;
}

- (void)setPieColor:(UIColor *)pieColor {
    if ([_pieColor isEqual:pieColor])
        return;
    
    _pieColor = pieColor;
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf setNeedsLayout];
    });
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    if (_borderWidth == borderWidth)
        return;
    
    _borderWidth = borderWidth;
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf setNeedsLayout];
    });
}

- (CGFloat)borderWidth {
    return _borderWidth;
}

- (void)setBorderColor:(UIColor *)borderColor {
    if ([_borderColor isEqual:borderColor])
        return;
    
    _borderColor = borderColor;
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf setNeedsLayout];
    });
}

- (UIColor *)borderColor {
    return _borderColor;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        _borderWidth = 1.0f;    // default
        _borderColor = [UIColor grayColor];
        
        one = [[UIImageView alloc] initWithFrame:frame];
        two = [[UIImageView alloc] initWithFrame:frame];
        three = [[UIImageView alloc] initWithFrame:frame];
        four = [[UIImageView alloc] initWithFrame:frame];
        
        for (UIImageView *iv in [self imageViews]) {
            iv.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
            iv.hidden = YES;
            iv.contentMode = UIViewContentModeScaleAspectFill;
            iv.clipsToBounds = YES;
            
            iv.layer.borderColor = _borderColor.CGColor;
            iv.layer.borderWidth = _borderWidth;
            
            [self addSubview:iv];
        }
        
        CGRect decoratorRect = CGRectMake(0, 0, 50, 50);
        onePie = [[M13ProgressViewPie alloc] initWithFrame:decoratorRect];
        twoPie = [[M13ProgressViewPie alloc] initWithFrame:decoratorRect];
        threePie = [[M13ProgressViewPie alloc] initWithFrame:decoratorRect];
        fourPie = [[M13ProgressViewPie alloc] initWithFrame:decoratorRect];
        
        oneAlert = [[UIImageView alloc] initWithFrame:decoratorRect];
        twoAlert = [[UIImageView alloc] initWithFrame:decoratorRect];
        threeAlert = [[UIImageView alloc] initWithFrame:decoratorRect];
        fourAlert = [[UIImageView alloc] initWithFrame:decoratorRect];
        
        FAKIcon *alert = [FAKIonIcons alertCircledIconWithSize:30.0f];
        [alert addAttribute:NSForegroundColorAttributeName value:[UIColor redColor]];
        FAKIcon *circle = [FAKIonIcons recordIconWithSize:50.0f];
        [circle addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
        UIImage *alertImage = [UIImage imageWithStackedIcons:@[ circle, alert ]
                                                   imageSize:CGSizeMake(50, 50)];
        
        for (int i = 0; i < 4; i++) {
            M13ProgressViewPie *pie = [self progressViews][i];
            UIImageView *iv = [self imageViews][i];
            pie.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin   |
                                    UIViewAutoresizingFlexibleRightMargin  |
                                    UIViewAutoresizingFlexibleTopMargin    |
                                    UIViewAutoresizingFlexibleBottomMargin);
            pie.hidden = YES;
            pie.backgroundRingWidth = _pieBorderWidth;
            pie.primaryColor = _pieColor;
            pie.secondaryColor = _pieColor;
            [iv addSubview:pie];
            pie.center = iv.center;
            
            UIImageView *alertIv = [self alertImageViews][i];
            alertIv.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin  |
                                        UIViewAutoresizingFlexibleRightMargin   |
                                        UIViewAutoresizingFlexibleTopMargin     |
                                        UIViewAutoresizingFlexibleBottomMargin);
            alertIv.clipsToBounds = YES;
            alertIv.hidden = YES;
            [iv addSubview:alertIv];
            alertIv.center = iv.center;
            alertIv.image = alertImage;
        }
    }
    
    return self;
}

- (void)layoutSubviews {
    
    for (UIImageView *iv in [self imageViews]) {
        iv.layer.borderWidth = _borderWidth;
        iv.layer.borderColor = _borderColor.CGColor;
    }
    
    for (M13ProgressViewPie *pie in [self progressViews]) {
        pie.backgroundRingWidth = _pieBorderWidth;
        pie.primaryColor = _pieColor;
        pie.secondaryColor = _pieColor;
    }
    
    if (_imageCount == 1) {
        // single photo, don't crop it
        one.contentMode = UIViewContentModeScaleAspectFit;

        one.hidden = NO;
        two.hidden = three.hidden = four.hidden = YES;
        
        one.frame = self.bounds;
    } else if (_imageCount == 2) {
        one.contentMode = UIViewContentModeScaleAspectFill;

        one.hidden = two.hidden = NO;
        three.hidden = four.hidden = YES;
        
        one.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y,
                               self.bounds.size.width, self.bounds.size.height / 2);
        two.frame = CGRectMake(self.bounds.origin.x, self.bounds.size.height / 2,
                               self.bounds.size.width, self.bounds.size.height / 2);
    } else if (_imageCount == 3) {
        one.contentMode = UIViewContentModeScaleAspectFill;

        one.hidden = two.hidden = three.hidden = NO;
        four.hidden = YES;
        
        one.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y,
                               self.bounds.size.width, self.bounds.size.height / 2);
        two.frame = CGRectMake(self.bounds.origin.x, self.bounds.size.height / 2,
                               self.bounds.size.width / 2, self.bounds.size.height / 2);
        three.frame = CGRectMake(self.bounds.size.width / 2, self.bounds.size.height / 2,
                                 self.bounds.size.width / 2, self.bounds.size.height / 2);
    } else if (_imageCount == 4) {
        one.contentMode = UIViewContentModeScaleAspectFill;

        one.hidden = two.hidden = three.hidden = four.hidden = NO;
        
        one.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y,
                               self.bounds.size.width / 2, self.bounds.size.height / 2);
        two.frame = CGRectMake(self.bounds.size.width / 2, self.bounds.origin.y,
                               self.bounds.size.width / 2, self.bounds.size.height / 2);
        three.frame = CGRectMake(self.bounds.origin.x, self.bounds.size.height / 2,
                                 self.bounds.size.width / 2, self.bounds.size.height / 2);
        four.frame = CGRectMake(self.bounds.size.width / 2, self.bounds.size.height / 2,
                                self.bounds.size.width / 2, self.bounds.size.height / 2);
    }
    
    [super layoutSubviews];
}

@end
