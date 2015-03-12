//
//  ObsCameraViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/24/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <DBCamera/DBCameraManager.h>

#import "ObsCameraViewController.h"
#import "ObsCameraView.h"

@interface DBCameraViewController ()
- (DBCameraView *)customCamera;
@end

@interface ObsCameraViewController ()

@end

@implementation ObsCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Camera", @"Title for the camera screen during create observation, mainly seen in the back button when you move on from the camera.");
    
    NSLog(@"whitebalancemode is %d", self.cameraManager.whiteBalanceMode);

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)openLibrary {
    if ([self.delegate respondsToSelector:@selector(openLibrary)])
        [self.delegate performSelector:@selector(openLibrary)];
}

- (void)noPhoto {
    if ([self.delegate respondsToSelector:@selector(noPhoto)])
        [self.delegate performSelector:@selector(noPhoto)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    if (size.width > size.height) {
        [((ObsCameraView *)self.customCamera) layoutForLandscape];
    } else {
        [((ObsCameraView *)self.customCamera) layoutForPortrait];
    }
}

@end
