//
//  MultiImageView.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/26/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <Photos/Photos.h>
#import <M13ProgressSuite/M13ProgressViewPie.h>

#import "MultiImageView.h"
#import "UIColor+INaturalist.h"

@interface MultiImageView () {
    NSArray *_assets;
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

- (void)setAssets:(NSArray *)assets {
    _assets = assets;
    [self layoutIfNeeded];
    NSArray *ivs = @[ one, two, three, four ];
    for (id asset in assets) {
        NSInteger idx = [assets indexOfObject:asset];
        UIImageView *iv = ivs[idx];

        if ([asset isKindOfClass:[UIImage class]]) {
            [iv setImage:(UIImage *)asset];
        } else {
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            
            options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
            options.networkAccessAllowed = YES;
            options.resizeMode = PHImageRequestOptionsResizeModeNone;

            options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([iv viewWithTag:0x99]) {
                        M13ProgressViewPie *progressView = [iv viewWithTag:0x99];
                        [progressView setProgress:progress animated:YES];
                    }
                });
            };
            
            [[PHImageManager defaultManager] requestImageForAsset:asset
                                                       targetSize:iv.bounds.size
                                                      contentMode:PHImageContentModeAspectFill
                                                          options:options
                                                    resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                                        NSNumber *isDegraded = [info valueForKey:PHImageResultIsDegradedKey];
                                                        if ([isDegraded boolValue]) {
                                                            if (![iv viewWithTag:0x99]) {
                                                                M13ProgressViewPie *progressView = [[M13ProgressViewPie alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
                                                                progressView.primaryColor = [UIColor lightGrayColor];
                                                                progressView.secondaryColor = [UIColor lightGrayColor];
                                                                progressView.backgroundRingWidth = 2.0f;
                                                                progressView.tag = 0x99;
                                                                progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleWidth;
                                                                [iv addSubview:progressView];
                                                                progressView.center = iv.center;
                                                            }
                                                        } else {
                                                            UIView *view = [iv viewWithTag:0x99];
                                                            [view removeFromSuperview];
                                                        }
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                            [iv setImage:result];
                                                        });
                                                    }];
        }
    }
}

- (NSArray *)assets {
    return _assets;
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
    
    if (self.assets.count == 1) {
        // single photo, don't crop it
        one.contentMode = UIViewContentModeScaleAspectFit;

        one.hidden = NO;
        two.hidden = three.hidden = four.hidden = YES;
        
        one.frame = self.bounds;
    } else if (self.assets.count == 2) {
        one.contentMode = UIViewContentModeScaleAspectFill;

        one.hidden = two.hidden = NO;
        three.hidden = four.hidden = YES;
        
        one.frame = CGRectMake(self.frame.origin.x, self.bounds.origin.y,
                               self.bounds.size.width, self.bounds.size.height / 2);
        two.frame = CGRectMake(self.frame.origin.x, self.bounds.size.height / 2,
                               self.bounds.size.width, self.bounds.size.height / 2);
    } else if (self.assets.count == 3) {
        one.contentMode = UIViewContentModeScaleAspectFill;

        one.hidden = two.hidden = three.hidden = NO;
        four.hidden = YES;
        
        one.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y,
                               self.bounds.size.width, self.bounds.size.height / 2);
        two.frame = CGRectMake(self.bounds.origin.x, self.bounds.size.height / 2,
                               self.bounds.size.width / 2, self.bounds.size.height / 2);
        three.frame = CGRectMake(self.bounds.size.width / 2, self.bounds.size.height / 2,
                                 self.bounds.size.width / 2, self.bounds.size.height / 2);
    } else if (self.assets.count == 4) {
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
