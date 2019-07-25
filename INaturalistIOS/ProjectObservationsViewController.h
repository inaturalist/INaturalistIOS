//
//  ProjectObservationViewController.h
//  iNaturalist
//
//  Created by Alex Shepard on 10/7/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ObservationVisualization.h"

@class Observation;

@interface ProjectObservationsViewController : UITableViewController

@property id <ObservationVisualization> observation;
@property BOOL isReadOnly;

@end
