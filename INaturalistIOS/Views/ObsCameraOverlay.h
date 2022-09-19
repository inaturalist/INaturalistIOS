//
//  ObsCameraOverlay.h
//  iNaturalist
//
//  Created by Alex Shepard on 3/17/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ObsCameraOverlay : UIView

@property UIButton *close;
@property UIButton *camera;
@property UIButton *flash;

@property UIButton *noPhoto;
@property UIButton *shutter;
@property UIButton *library;

- (void)configureFlashForMode:(UIImagePickerControllerCameraFlashMode)mode;

@end
