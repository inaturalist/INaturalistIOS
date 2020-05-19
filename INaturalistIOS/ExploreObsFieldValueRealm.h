//
//  ExploreObsFieldValueRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 4/26/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>

#import "ExploreObsFieldValue.h"
#import "ExploreObsFieldRealm.h"
#import "Uploadable.h"

@class ExploreObservationRealm;

@interface ExploreObsFieldValueRealm : RLMObject <Uploadable>

@property NSInteger obsFieldValueId;
@property NSString *value;
@property NSString *uuid;
@property ExploreObsFieldRealm *obsField;

@property NSDate *timeSynced;
@property NSDate *timeUpdatedLocally;

@property (readonly) ExploreObservationRealm *observation;

+ (NSDictionary *)valueForMantleModel:(ExploreObsFieldValue *)model;
+ (NSDictionary *)valueForCoreDataModel:(id)model;

@end

RLM_ARRAY_TYPE(ExploreObsFieldValueRealm)
