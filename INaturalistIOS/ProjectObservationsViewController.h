//
//  ProjectObservationViewController.h
//  iNaturalist
//
//  Created by Alex Shepard on 10/7/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

@import UIKit;
@import Realm;

#import "ExploreObservationRealm.h"

@interface ProjectObservationsViewController : UITableViewController

@property ExploreObservationRealm *observation;

@end
