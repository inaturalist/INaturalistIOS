//
//  ConfirmObservationViewController.h
//  iNaturalist
//
//  Created by Alex Shepard on 9/4/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ExploreObservationRealm;

@interface ObsEditV2ViewController : UIViewController

@property ExploreObservationRealm *standaloneObservation;
@property ExploreObservationRealm *persistedObservation;
@property BOOL shouldContinueUpdatingLocation;
@property BOOL isMakingNewObservation;
@property UITableView *tableView;

@end
