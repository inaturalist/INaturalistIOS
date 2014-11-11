//
//  ExploreContainerViewController.m
//  Explore Prototype
//
//  Created by Alex Shepard on 9/12/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//


#import "ExploreContainerViewController.h"
#import "UIColor+ExploreColors.h"

@implementation ExploreContainerViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        
        self.navigationItem.titleView = ({
            self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[]];
            [self.segmentedControl addTarget:self
                                      action:@selector(segmentedControlChanged:)
                            forControlEvents:UIControlEventValueChanged];
            self.segmentedControl.tintColor = [UIColor inatGreen];
            self.segmentedControl;
        });

    }
    return self;
}

#pragma mark - Container Stuff
- (void)segmentedControlChanged:(UISegmentedControl *)control {
    // hide the old view controller
    [self hideContentController:self.selectedViewController];
    
    // show the selected view controller
    UIViewController *content = [self.viewControllers objectAtIndex:control.selectedSegmentIndex];
    [self displayContentController:content];
}

- (void)displayContentController:(UIViewController*)content {
    self.selectedViewController = content;
    [self addChildViewController:content];
    content.view.frame = [self frameForContentController];
    
    if (self.overlayView)
        [self.view insertSubview:content.view
                    belowSubview:self.overlayView];
    else
        [self.view addSubview:content.view];
    
    [content didMoveToParentViewController:self];
}

- (void)hideContentController:(UIViewController*)content {
    [content willMoveToParentViewController:nil];
    [content.view removeFromSuperview];
    [content removeFromParentViewController];
}

- (CGRect)frameForContentController {
    return self.view.bounds;
}


@end
