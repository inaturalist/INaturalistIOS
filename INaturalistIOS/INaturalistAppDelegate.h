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
{
    NSManagedObjectModel *managedObjectModel;
}
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) RKObjectManager *photoObjectManager;
@property (strong, nonatomic) LoginController *loginController;

- (void)configureRestKit;
- (BOOL)loggedIn;
- (NSManagedObjectModel *)getManagedObjectModel;
- (void)showMainUI;
@end
