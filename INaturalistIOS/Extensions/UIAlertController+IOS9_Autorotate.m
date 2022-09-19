//
//  UIAlertController+IOS9_Autorotate.m
//  iNaturalist
//
//  Created by Alex Shepard on 9/17/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import "UIAlertController+IOS9_Autorotate.h"

// workaround for an iOS9 autorotate bug
// see http://stackoverflow.com/questions/31406820/uialertcontrollersupportedinterfaceorientations-was-invoked-recursively
@implementation UIAlertController (IOS9_Autorotate)
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}
- (BOOL)shouldAutorotate {
    return NO;
}
@end
