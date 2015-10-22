//
//  SignupSplashViewController.h
//  iNaturalist
//
//  Created by Alex Shepard on 5/14/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SplitTextButton;

@interface SignupSplashViewController : UIViewController

@property NSString *reason;
@property BOOL skippable;
@property BOOL cancellable;
@property BOOL animateIn;

@property (nonatomic, copy) void(^skipAction)();


// expose UI elements for transition animator
@property UIImageView *logoImageView;
@property UILabel *reasonLabel;
@property SplitTextButton *loginFaceButton;
@property SplitTextButton *loginGButton;
@property SplitTextButton *signupEmailButton;
@property UIButton *signinEmailButton;
@property UIButton *skipButton;
@property UIImageView *backgroundImageView;
@property UIView *blurView;

@end
