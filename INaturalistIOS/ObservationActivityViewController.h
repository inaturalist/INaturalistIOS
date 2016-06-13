//
//  ObservationActivityViewController.h
//  iNaturalist
//
//  Created by Ryan Waggoner on 10/23/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Observation;

@interface ObservationActivityViewController : UITableViewController

@property (strong, nonatomic) Observation *observation;
- (BOOL)checkForNetworkAndWarn;
@end
