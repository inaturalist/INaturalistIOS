//
//  ExploreObservationFieldValueRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 1/12/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>

#import "ExploreObservationFieldValue.h"
#import "ExploreObservationFieldRealm.h"

@interface ExploreObservationFieldValueRealm : RLMObject

@property NSInteger fieldId;
@property NSString *uuid;
@property NSString *value;

- (instancetype)initWithMantleModel:(ExploreObservationFieldValue *)model;

@end

RLM_ARRAY_TYPE(ExploreObservationFieldValueRealm)
