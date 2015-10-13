//
//  INaturalistAppDelegate.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SignUserForGolanProject.h"

@class LoginController;

@interface INaturalistAppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) RKObjectManager *photoObjectManager;
@property (strong, nonatomic) LoginController *loginController;
@property (strong, nonatomic) SignUserForGolanProject *golan;
- (BOOL)loggedIn;
- (void)showMainUI;
- (void)showInitialSignupUI;

- (void)reconfigureForNewBaseUrl;

@end
