//
//  ExploreContainerViewController.h
//  Explore Prototype
//
//  Created by Alex Shepard on 9/12/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ExploreViewControllerControlIcon <NSObject>
@property (readonly) UIImage *controlIcon;
@end

@interface ExploreContainerViewController : UIViewController

@property UISegmentedControl *segmentedControl;

@property NSArray *viewControllers;
@property UIViewController *selectedViewController;

@end


