//
//  ExploreContainerViewController.h
//  Explore Prototype
//
//  Created by Alex Shepard on 9/12/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 An object that adopts the ExploreViewControllerControlIcon protocol
 is responsible for providing a UIImage icon. A container view controller
 will present some control (ie a segmented control) for switching between
 child view controllers. Each child presents a different control icon,
 allowing the user to choose which child to view.
 
 @see ExploreContainerViewController
 */
@protocol ExploreViewControllerControlIcon <NSObject>
@property (readonly) UIImage *controlIcon;
@end

/**
 The ExploreContainerViewController class presents a container view
 controller that can be filled with child view controllers. It also
 presents a UISegmentedControl that allows the user to pick between
 the children. Children implement the ExploreViewControllerControlIcon
 protocol to provide icons/images for the UISegmentedControl.
 
 @see ExploreViewControllerControlIcon
 */
@interface ExploreContainerViewController : UIViewController

/**
 The segmented control that is presented in the Navigation bar of
 this container UIViewController. Manipulating the segmented control
 allows the user to display the different child view controllers.
 */
@property UISegmentedControl *segmentedControl;

/**
 The children of this container view controller.
 */
@property NSArray *viewControllers;

/**
 The currently selected view controller of this container.
 */
@property UIViewController *selectedViewController;

/**
 Subclasses can implement an overlay view to provide a view that
 is always above child of this container, regardless of which child
 is active.
 */
@property UIView *overlayView;

/**
 Callback when the user changes the segmented control. Switch this container
 to show a new child view controller.
 */
- (void)segmentedControlChanged:(UISegmentedControl *)control;

/**
 Show a child view controller.
 */
- (void)displayContentController:(UIViewController*)content;

/**
 Hide a child view controller.
 */
- (void)hideContentController:(UIViewController*)content;

/**
 Frame for a child view controller.
 */
- (CGRect)frameForContentController;


@end


