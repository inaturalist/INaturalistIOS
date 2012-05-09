//
//  INaturalistAppDelegate.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface INaturalistAppDelegate : UIResponder <UIApplicationDelegate>
{
    NSManagedObjectModel *managedObjectModel;
}
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) RKObjectManager *photoObjectManager;

- (void)configureRestKit;
- (void)configureThree20;
- (BOOL)loggedIn;
- (NSManagedObjectModel *)getManagedObjectModel;
@end
