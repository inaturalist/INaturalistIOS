//
//  SignupSplashViewController.h
//  iNaturalist
//
//  Created by Alex Shepard on 5/14/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SignupSplashViewController : UIViewController

@property NSString *reason;
@property BOOL skippable;
@property BOOL cancellable;
@property BOOL animateIn;

@property (nonatomic, copy) void(^skipAction)();

@end
