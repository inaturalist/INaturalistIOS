//
//  OnboardingLoginViewController.h
//  iNaturalist
//
//  Created by Alex Shepard on 8/4/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OnboardingLoginViewController : UIViewController

@property BOOL skippable;
@property BOOL startsInLoginMode;
@property (nonatomic, copy) void(^skipAction)();
@property (nonatomic, copy) void(^closeAction)();

@end
