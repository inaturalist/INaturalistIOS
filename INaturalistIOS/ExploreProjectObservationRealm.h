//
//  ExploreProjectObservationRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 4/27/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>

#import "ExploreProjectObservation.h"
#import "ExploreProjectRealm.h"
#import "Uploadable.h"

@class ExploreObservationRealm;

@interface ExploreProjectObservationRealm : RLMObject <Uploadable>

@property NSInteger projectObsId;
@property NSString *uuid;
@property ExploreProjectRealm *project;

@property NSDate *timeSynced;
@property NSDate *timeUpdatedLocally;

@property (readonly) ExploreObservationRealm *observation;

+ (NSDictionary *)valueForMantleModel:(ExploreProjectObservation *)model;
+ (NSDictionary *)valueForCoreDataModel:(id)model;

@end

RLM_ARRAY_TYPE(ExploreProjectObservationRealm)
