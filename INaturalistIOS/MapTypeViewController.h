//
//  MapTypeViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/7/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MapTypeViewController;

@protocol MapTypeViewControllerDelegate <NSObject>
@optional
- (void)mapTypeControllerDidChange:(MapTypeViewController *)controller mapType:(NSNumber *)mapType;
@end

@interface MapTypeViewController : UIViewController

@property (weak, nonatomic) IBOutlet UISegmentedControl *mapTypeControl;
@property (nonatomic, strong) id<MapTypeViewControllerDelegate>delegate;
@property (nonatomic, assign) NSInteger mapType;
- (IBAction)choseMapType:(id)sender;

@end
