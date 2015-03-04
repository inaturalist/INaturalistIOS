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
}
@property (nonatomic, strong) CALayer *focusBox, *exposeBox;
@end


@implementation ObsCameraView

- (void) buildInterface {
    
    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.translatesAutoresizingMaskIntoConstraints = NO;
    close.frame = CGRectZero;
    close.backgroundColor = [UIColor blueColor];
    [close setTitle:@"Close" forState:UIControlStateNormal];
    [close addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:close];
    
    UIButton *camera = [UIButton buttonWithType:UIButtonTypeSystem];
    camera.translatesAutoresizingMaskIntoConstraints = NO;
    camera.frame = CGRectZero;
    camera.backgroundColor = [UIColor blueColor];
    [camera setTitle:@"Front Camera" forState:UIControlStateNormal];
    [camera setTitle:@"Back Camera" forState:UIControlStateSelected];
    [camera addTarget:self action:@selector(changeCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:camera];
    
    UIButton *flash = [UIButton buttonWithType:UIButtonTypeSystem];
    flash.translatesAutoresizingMaskIntoConstraints = NO;
    flash.frame = CGRectZero;
    flash.backgroundColor = [UIColor blueColor];
    [flash setTitle:@"Flash On" forState:UIControlStateNormal];
    [flash setTitle:@"Flash Off" forState:UIControlStateSelected];
    [flash addTarget:self action:@selector(flashTriggerAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:flash];
    
    noPhoto = [UIButton buttonWithType:UIButtonTypeSystem];
    noPhoto.translatesAutoresizingMaskIntoConstraints = NO;
    noPhoto.frame = CGRectZero;
    noPhoto.backgroundColor = [UIColor blueColor];
    [noPhoto setTitle:@"No Photo" forState:UIControlStateNormal];
    [noPhoto addTarget:self action:@selector(noPhoto) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:noPhoto];
    
    UIButton *shutter = [UIButton buttonWithType:UIButtonTypeSystem];
    shutter.translatesAutoresizingMaskIntoConstraints = NO;
    shutter.frame = CGRectZero;
    shutter.backgroundColor = [UIColor blueColor];
    [shutter setTitle:@"SHUTTER" forState:UIControlStateNormal];
    [shutter addTarget:self action:@selector(triggerAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:shutter];
    
    UIButton *library = [UIButton buttonWithType:UIButtonTypeSystem];
    library.translatesAutoresizingMaskIntoConstraints = NO;
    library.frame = CGRectZero;
    library.backgroundColor = [UIColor blueColor];
    [library setTitle:@"Library" forState:UIControlStateNormal];
    [library addTarget:self action:@selector(libraryAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:library];

    
    NSDictionary *views = @{
                            @"close": close,
                            @"camera": camera,
                            @"flash": flash,
                            @"noPhoto": noPhoto,
                            @"shutter": shutter,
                            @"library": library,
                            };
    
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



    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[noPhoto(==60)]-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[library(==60)]-|"
                                                                 options:0
                                                                 metrics:0
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[shutter(==60)]-|"
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
    CGPoint tempPoint = (CGPoint)[recognizer locationInView:self];
    if ([self.delegate respondsToSelector:@selector(cameraView:focusAtPoint:)] && CGRectContainsPoint(self.previewLayer.frame, tempPoint)) {
        [self.delegate cameraView:self focusAtPoint:(CGPoint){ tempPoint.x, tempPoint.y - CGRectGetMinY(self.previewLayer.frame) }];
    }
    if ([self.delegate respondsToSelector:@selector(cameraView:exposeAtPoint:)] && CGRectContainsPoint(self.previewLayer.frame, tempPoint)) {
        [self.delegate cameraView:self exposeAtPoint:(CGPoint){ tempPoint.x, tempPoint.y - CGRectGetMinY(self.previewLayer.frame) }];
    }
    [self drawExposeBoxAtPointOfInterest:tempPoint andRemove:YES];
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


@end
