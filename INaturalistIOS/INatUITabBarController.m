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

@implementation INatUITabBarController

- (void)viewDidLoad
{
    UITabBarItem *item = [self.tabBar.items objectAtIndex:0];
    item.badgeValue = [NSString stringWithFormat:@"%d", 
                       [UIApplication sharedApplication].applicationIconBadgeNumber];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(handleNSManagedObjectContextDidSaveNotification:) 
                                                 name:NSManagedObjectContextDidSaveNotification 
                                               object:[Observation managedObjectContext]];
}

// make sure view controllers in the tabs can autorotate
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (toInterfaceOrientation == UIDeviceOrientationPortrait) return YES;
    return [self.selectedViewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

- (void)handleNSManagedObjectContextDidSaveNotification:(NSNotification *)notification
{
    int obsSyncCount = [Observation needingSyncCount];
    int photoSyncCount = [ObservationPhoto needingSyncCount];
    int theCount = obsSyncCount > 0 ? obsSyncCount : photoSyncCount;
    UITabBarItem *item = [self.tabBar.items objectAtIndex:0];
    if (theCount > 0) {
        item.badgeValue = [NSString stringWithFormat:@"%d", theCount];
    } else {
        item.badgeValue = nil;
    }
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:theCount];
}
@end
