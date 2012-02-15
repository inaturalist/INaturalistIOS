//
//  INatObserverViewController.h
//  INatObserver
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "INObservationFormViewController.h"

@class Observation;
@class ObservationStore;

@interface INatObserverViewController : UITableViewController <INObservationFormViewControllerDelegate>
@property (nonatomic, weak) Observation *selectedObservation;
@end
