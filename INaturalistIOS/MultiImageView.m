//
//  MultiImageView.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/26/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "MultiImageView.h"

@interface MultiImageView () {
    NSArray *_images;
    CGFloat _borderWidth;
    UIColor *_borderColor;
    
    UIImageView *one;
    UIImageView *two;
    UIImageView *three;
    UIImageView *four;
}
@end

@implementation MultiImageView

- (NSArray *)imageViews {
    return @[ one, two, three, four ];
}

- (void)setImages:(NSArray *)images {
    NSAssert(images.count < 5, @"MultiImageView can display at most four images.");
    
    _images = images;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setNeedsLayout];
    });
}

- (NSArray *)images {
    return _images;
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
        
    }
    
    return self;
}

- (void)layoutSubviews {
    
    for (UIImageView *iv in [self imageViews]) {
        iv.layer.borderWidth = _borderWidth;
        iv.layer.borderColor = _borderColor.CGColor;
    }
    
    if (self.images.count == 1) {
        // single photo, don't crop it
        one.contentMode = UIViewContentModeScaleAspectFit;

        one.hidden = NO;
        two.hidden = three.hidden = four.hidden = YES;
        
        one.frame = self.bounds;
        one.image = self.images[0];
        
    } else if (self.images.count == 2) {
        one.contentMode = UIViewContentModeScaleAspectFill;

        one.hidden = two.hidden = NO;
        three.hidden = four.hidden = YES;
        
        one.frame = CGRectMake(self.frame.origin.x, self.bounds.origin.y,
                               self.bounds.size.width, self.bounds.size.height / 2);
        two.frame = CGRectMake(self.frame.origin.x, self.bounds.size.height / 2,
                               self.bounds.size.width, self.bounds.size.height / 2);
        
        one.image = self.images[0];
        two.image = self.images[1];
        
    } else if (self.images.count == 3) {
        one.contentMode = UIViewContentModeScaleAspectFill;

        one.hidden = two.hidden = three.hidden = NO;
        four.hidden = YES;
        
        one.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y,
                               self.bounds.size.width, self.bounds.size.height / 2);
        two.frame = CGRectMake(self.bounds.origin.x, self.bounds.size.height / 2,
                               self.bounds.size.width / 2, self.bounds.size.height / 2);
        three.frame = CGRectMake(self.bounds.size.width / 2, self.bounds.size.height / 2,
                                 self.bounds.size.width / 2, self.bounds.size.height / 2);
        
        one.image = self.images[0];
        two.image = self.images[1];
        three.image = self.images[2];
        
    } else if (self.images.count == 4) {
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
        
        one.image = self.images[0];
        two.image = self.images[1];
        three.image = self.images[2];
        four.image = self.images[3];
    }
    
    [super layoutSubviews];
}

@end
