//
//  INaturalistAppDelegate.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LoginController;

@interface INaturalistAppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) LoginController *loginController;

- (BOOL)loggedIn;
- (void)showMainUI;
- (void)showInitialSignupUI;

@end


extern NSString *kInatCoreDataRebuiltNotification;
