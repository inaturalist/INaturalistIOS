//
//  ProjectObsFieldViewController.h
//  iNaturalist
//
//  Created by Alex Shepard on 10/13/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Observation;
@class ObservationField;
@class ProjectObservationField;
@class ObservationFieldValue;

@interface ProjectObsFieldViewController : UIViewController

@property Observation *observation;
@property ProjectObservationField *projectObsField;
@property ObservationFieldValue *obsFieldValue;

@end
