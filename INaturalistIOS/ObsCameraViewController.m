//
//  ObsCameraViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/24/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "ObsCameraViewController.h"

@interface ObsCameraViewController ()

@end

@implementation ObsCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Camera", @"Title for the camera screen during create observation, mainly seen in the back button when you move on from the camera.");
}

- (void)openLibrary {
    if ([self.delegate respondsToSelector:@selector(openLibrary)])
        [self.delegate performSelector:@selector(openLibrary)];
}

- (void)noPhoto {
    NSLog(@"no photo!");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

@end
