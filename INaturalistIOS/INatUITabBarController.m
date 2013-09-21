//
//  INatUITabBarController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/23/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "INatUITabBarController.h"
#import "Observation.h"
#import "ObservationPhoto.h"
#import "INatWebController.h"

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
    NSInteger obsSyncCount = [Observation needingSyncCount];
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
