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

@protocol ProjectObservationsViewControllerDelegate <NSObject>
@optional
- (void)projectObsDelegateDeletedProjectObservation:(ExploreProjectObservationRealm *)po;
- (void)projectObsDelegateDeletedObsFieldValue:(ExploreObsFieldValueRealm *)ofv;
@end


@interface ProjectObservationsViewController : UITableViewController

@property ExploreObservationRealm *observation;
@property (weak, nonatomic) id <ProjectObservationsViewControllerDelegate> delegate;

@end
