//
//  ObsCameraView.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/24/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonIcons.h>

#import "ObsCameraView.h"
#import "UIColor+ExploreColors.h"

@interface DBCameraView ()
- (void)createGesture;
@end

@interface ObsCameraView () {
    UIButton *noPhoto;
    UIView *topBar, *bottomBar;
    UIButton *close, *camera, *flash, *shutter, *library;
}
@property (nonatomic, strong) CALayer *focusBox, *exposeBox;
@end


@implementation ObsCameraView

- (void) buildInterface {
    
    topBar = [[UIView alloc] initWithFrame:CGRectZero];
    topBar.translatesAutoresizingMaskIntoConstraints = NO;
    topBar.backgroundColor = [UIColor blackColor];
    [self addSubview:topBar];
    
    bottomBar = [[UIView alloc] initWithFrame:CGRectZero];
    bottomBar.translatesAutoresizingMaskIntoConstraints = NO;
    bottomBar.backgroundColor = [UIColor blackColor];
    [self addSubview:bottomBar];
    
    close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.translatesAutoresizingMaskIntoConstraints = NO;
    close.frame = CGRectZero;
    close.backgroundColor = [UIColor blackColor];
    close.tintColor = [UIColor whiteColor];
    [close setTitle:@"Close" forState:UIControlStateNormal];
    [close addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:close];
    
    camera = [UIButton buttonWithType:UIButtonTypeSystem];
    camera.translatesAutoresizingMaskIntoConstraints = NO;
    camera.frame = CGRectZero;
    camera.backgroundColor = [UIColor blackColor];
    camera.tintColor = [UIColor whiteColor];
    [camera setTitle:@"Front Camera" forState:UIControlStateNormal];
    [camera setTitle:@"Back Camera" forState:UIControlStateSelected];
    [camera addTarget:self action:@selector(changeCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:camera];
    
    flash = [UIButton buttonWithType:UIButtonTypeSystem];
    flash.translatesAutoresizingMaskIntoConstraints = NO;
    flash.frame = CGRectZero;
    flash.backgroundColor = [UIColor blackColor];
    flash.tintColor = [UIColor whiteColor];
    [flash setTitle:@"Flash On" forState:UIControlStateNormal];
    [flash setTitle:@"Flash Off" forState:UIControlStateSelected];
    [flash addTarget:self action:@selector(flashTriggerAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:flash];
    
    noPhoto = [UIButton buttonWithType:UIButtonTypeSystem];
    noPhoto.translatesAutoresizingMaskIntoConstraints = NO;
    noPhoto.frame = CGRectZero;
    noPhoto.backgroundColor = [UIColor blackColor];
    noPhoto.tintColor = [UIColor whiteColor];
    noPhoto.titleLabel.numberOfLines = 2;
    //noPhoto.titleLabel.font = [UIFont boldSystemFontOfSize:noPhoto.titleLabel.font.pointSize];
    noPhoto.titleLabel.textAlignment = NSTextAlignmentCenter;
    [noPhoto setTitle:@"NO\nPHOTO" forState:UIControlStateNormal];
    [noPhoto addTarget:self action:@selector(noPhoto) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:noPhoto];
    
    shutter = [UIButton buttonWithType:UIButtonTypeSystem];
    shutter.translatesAutoresizingMaskIntoConstraints = NO;
    shutter.frame = CGRectZero;
    shutter.backgroundColor = [UIColor blackColor];
    
    FAKIcon *circleIcon = [FAKIonIcons ios7CircleFilledIconWithSize:75.0f];
    [circleIcon addAttribute:NSForegroundColorAttributeName value:[UIColor inatGreen]];
    FAKIcon *circleOutline = [FAKIonIcons ios7CircleOutlineIconWithSize:75.0f];
    [circleOutline addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
    UIImage *shutterImage = [[UIImage imageWithStackedIcons:@[ circleIcon, circleOutline ] imageSize:CGSizeMake(75.0f, 75.0f)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [shutter setImage:shutterImage
             forState:UIControlStateNormal];
    
    //[shutter setTitle:@"SHUTTER" forState:UIControlStateNormal];
    [shutter addTarget:self action:@selector(triggerAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:shutter];
    
    library = [UIButton buttonWithType:UIButtonTypeSystem];
    library.translatesAutoresizingMaskIntoConstraints = NO;
    library.frame = CGRectZero;
    library.tintColor = [UIColor whiteColor];
    library.backgroundColor = [UIColor blackColor];
    FAKIcon *libIcon = [FAKIonIcons imagesIconWithSize:45.0f];
    [library setAttributedTitle:libIcon.attributedString forState:UIControlStateNormal];
    [library addTarget:self action:@selector(libraryAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:library];
    
    
    
    NSDictionary *views = @{
                            @"topBar": topBar,
                            @"bottomBar": bottomBar,
                            @"close": close,
                            @"camera": camera,
                            @"flash": flash,
                            @"noPhoto": noPhoto,
                            @"shutter": shutter,
                            @"library": library,
                            };
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[topBar]-0-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[bottomBar]-0-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];


    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[close(==100)]"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[flash(==100)]-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[camera(==100)]"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:camera
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0f
                                                      constant:0.0f]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[noPhoto(==100)]"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[library(==100)]-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[shutter(==100)]"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:shutter
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0f
                                                      constant:0.0f]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[topBar(==40)]"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[bottomBar(==80)]-0-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[close(==40)]"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[flash(==40)]"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[camera(==40)]"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];


    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[noPhoto(==80)]-0-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[library(==80)]-0-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[shutter(==80)]-0-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];


    
    [self.previewLayer addSublayer:self.focusBox];
    [self.previewLayer addSublayer:self.exposeBox];
    
    // create the standard DBcamera gestures
    [self createGesture];
    // remove the separate tap to focus / tap to expose gestures
    [self removeGestureRecognizer:self.singleTap];
    [self removeGestureRecognizer:self.doubleTap];
    
    // add a tap to focus and expose gesture, to match the native iOS camera & imagepicker behavior
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToFocusAndExpose:)];
    [singleTap setDelaysTouchesEnded:NO];
    [singleTap setNumberOfTapsRequired:1];
    [singleTap setNumberOfTouchesRequired:1];
    [self addGestureRecognizer:singleTap];
}

- (void)buildInterfaceShowNoPhoto:(BOOL)showsNoPhoto {
    [self buildInterface];
    
    noPhoto.hidden = !showsNoPhoto;
}

- (void)noPhoto {
    if ([self.delegate respondsToSelector:@selector(noPhoto)])
        [self.delegate performSelector:@selector(noPhoto)];
}

- (void)tapToFocusAndExpose:(UIGestureRecognizer *)recognizer {
    CGPoint tempPoint = [recognizer locationInView:self];
    CGPoint convertedPoint = [self.previewLayer convertPoint:tempPoint fromLayer:self.layer];

    if ([self.delegate respondsToSelector:@selector(cameraView:focusAtPoint:)] && CGRectContainsPoint(self.previewLayer.frame, convertedPoint)) {
        [self.delegate cameraView:self focusAtPoint:(CGPoint){ convertedPoint.x, convertedPoint.y - CGRectGetMinY(self.previewLayer.frame) }];
    }
    if ([self.delegate respondsToSelector:@selector(cameraView:exposeAtPoint:)] && CGRectContainsPoint(self.previewLayer.frame, convertedPoint)) {
        [self.delegate cameraView:self exposeAtPoint:(CGPoint){ convertedPoint.x, convertedPoint.y - CGRectGetMinY(self.previewLayer.frame) }];
    }
    [self drawExposeBoxAtPointOfInterest:convertedPoint andRemove:YES];
}

#pragma mark - Focus / Expose Box

- (CALayer *) focusBox {
    // only draw the expose box
    return [CALayer new];
}

- (CALayer *) exposeBox {
    if (!_exposeBox) {
        _exposeBox = [[CALayer alloc] init];
        [_exposeBox setCornerRadius:50.0f];
        [_exposeBox setBounds:CGRectMake(0.0f, 0.0f, 100.0f, 100.0f)];
        [_exposeBox setBorderWidth:4.0f];
        [_exposeBox setBorderColor:[[UIColor inatGreen] CGColor]];
        [_exposeBox setOpacity:0];
        
    }
    
    return _exposeBox;
}

- (void) drawFocusBoxAtPointOfInterest:(CGPoint)point andRemove:(BOOL)remove {
    [super draw:_focusBox atPointOfInterest:point andRemove:remove];
}

- (void) drawExposeBoxAtPointOfInterest:(CGPoint)point andRemove:(BOOL)remove {
    [super draw:_exposeBox atPointOfInterest:point andRemove:remove];
}

#pragma mark - orientation
- (void)layoutForPortrait {
    [self removeConstraints:self.constraints];
    
    NSDictionary *views = @{
                            @"topBar": topBar,
                            @"bottomBar": bottomBar,
                            @"close": close,
                            @"camera": camera,
                            @"flash": flash,
                            @"noPhoto": noPhoto,
                            @"shutter": shutter,
                            @"library": library,
                            };
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[topBar]-0-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[bottomBar]-0-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[close(==100)]"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[flash(==100)]-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[camera(==100)]"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:camera
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0f
                                                      constant:0.0f]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[noPhoto(==100)]"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[library(==100)]-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[shutter(==100)]"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:shutter
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0f
                                                      constant:0.0f]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[topBar(==40)]"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[bottomBar(==80)]-0-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[close(==40)]"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[flash(==40)]"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[camera(==40)]"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[noPhoto(==80)]-0-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[library(==80)]-0-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[shutter(==80)]-0-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
}

- (void)layoutForLandscape {
    [self removeConstraints:self.constraints];
    
    NSDictionary *views = @{
                            @"topBar": topBar,
                            @"bottomBar": bottomBar,
                            @"close": close,
                            @"camera": camera,
                            @"flash": flash,
                            @"noPhoto": noPhoto,
                            @"shutter": shutter,
                            @"library": library,
                            };
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[topBar]-0-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[bottomBar]-0-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[close(==100)]"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[flash(==100)]-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[camera(==100)]"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:camera
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.0f
                                                      constant:0.0f]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[noPhoto(==100)]"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[library(==100)]-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[shutter(==100)]"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:shutter
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.0f
                                                      constant:0.0f]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[topBar(==40)]"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[bottomBar(==80)]-0-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[close(==40)]"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[flash(==40)]"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[camera(==40)]"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[noPhoto(==80)]-0-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[library(==80)]-0-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[shutter(==80)]-0-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
}


@end
