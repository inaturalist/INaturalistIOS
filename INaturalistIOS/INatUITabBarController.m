//
//  INatUITabBarController.m
//  INaturalistIOS
//
//  Created by Ken-ichi Ueda on 2/23/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "INatUITabBarController.h"

@implementation INatUITabBarController

// make sure view controllers in the tabs can autorotate
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return [self.selectedViewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
}
@end
