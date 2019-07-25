//
//  ProjectObsFieldViewController.h
//  iNaturalist
//
//  Created by Alex Shepard on 10/13/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ExploreObservationRealm;
@class ExploreObservationFieldRealm;
@class ExploreProjectObservationFieldRealm;
@class ExploreObservationFieldValueRealm;

@interface ProjectObsFieldViewController : UIViewController

@property ExploreObservationRealm *observation;
@property ExploreProjectObservationFieldRealm *projectObsField;
@property ExploreObservationFieldValueRealm *obsFieldValue;

@end
