//
//  INatUITabBarController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/23/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonIcons.h>

#import "INatUITabBarController.h"
#import "Observation.h"
#import "ObservationPhoto.h"
#import "INatWebController.h"

@interface INatUITabBarController () <UITabBarDelegate, UITabBarControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    
}
@end

@implementation INatUITabBarController

- (void)viewDidLoad
{
    [self setObservationsTabBadge];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(handleUserSavedObservationNotification:) 
                                                 name:INatUserSavedObservationNotification 
                                               object:nil];
    
    TTNavigator* navigator = [TTNavigator navigator];
    navigator.delegate = self;
    
    // make sure tabs fit OS version
    if (SYSTEM_VERSION_LESS_THAN(@"6.0")) {
        NSMutableArray * vcs = [NSMutableArray
                                arrayWithArray:[self viewControllers]];
        [vcs removeObjectAtIndex:3]; // remove guides tab
        [self setViewControllers:vcs];
    }
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        self.tabBar.translucent = NO;
    }
    
    self.delegate = self;
    
    UIViewController *vc = [[UIViewController alloc] initWithNibName:nil bundle:nil];
    FAKIcon *camera = [FAKIonIcons ios7CameraIconWithSize:55];
    vc.tabBarItem.image = [camera imageWithSize:CGSizeMake(55, 55)];
    
    NSMutableArray *vcs = [self.viewControllers mutableCopy];
    [vcs insertObject:vc atIndex:2];
    [self setViewControllers:vcs animated:NO];
    
    self.selectedIndex = 4;
    
    [super viewDidLoad];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 NSLog(@"dismissed");
                             }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 NSLog(@"cancelled, dismissed.");
                             }];
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    
    if ([tabBarController.viewControllers indexOfObject:viewController] == 2) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.delegate = self;
        [tabBarController presentViewController:picker
                                       animated:YES
                                     completion:^{
                                         NSLog(@"done presenting");
                                     }];
        return NO;
    }

    return YES;
}

// make sure view controllers in the tabs can autorotate
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (toInterfaceOrientation == UIDeviceOrientationPortrait) return YES;
    return [self.selectedViewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
}
- (NSUInteger)supportedInterfaceOrientations
{
    if ([self.selectedViewController isKindOfClass:UINavigationController.class]) {
        UINavigationController *nc = (UINavigationController *)self.selectedViewController;
        return [nc.visibleViewController supportedInterfaceOrientations];
    } else {
        return [self.selectedViewController supportedInterfaceOrientations];
    }
}

- (void)handleUserSavedObservationNotification:(NSNotification *)notification
{
    [self setObservationsTabBadge];
}

- (void)setObservationsTabBadge
{
    NSInteger obsSyncCount = [Observation needingSyncCount] + [Observation deletedRecordCount];
    NSInteger photoSyncCount = [ObservationPhoto needingSyncCount];
    NSInteger theCount = obsSyncCount > 0 ? obsSyncCount : photoSyncCount;
    UITabBarItem *item = [self.tabBar.items objectAtIndex:0];
    if (theCount > 0) {
        item.badgeValue = [NSString stringWithFormat:@"%d", theCount];
    } else {
        item.badgeValue = nil;
    }
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:theCount];
}

#pragma mark - TTNagigatorDelegate
// http://stackoverflow.com/questions/8771176/ttnavigator-not-pushing-onto-navigation-stack
- (BOOL)navigator: (TTBaseNavigator *)navigator shouldOpenURL:(NSURL *)url {
    UINavigationController *nc;
    if ([self.selectedViewController.presentedViewController isKindOfClass:UINavigationController.class]) {
        nc = (UINavigationController *)self.selectedViewController.presentedViewController;
    } else if ([self.selectedViewController isKindOfClass:UINavigationController.class]) {
        nc = (UINavigationController *)self.selectedViewController;
    }
    if (nc) {
        INatWebController *webController = [[INatWebController alloc] init];
        [webController openURL:url];
        [nc pushViewController:webController animated:YES];
    }
    return NO;
}
@end
