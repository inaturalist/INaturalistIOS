//
//  ExploreProjectObservationFieldRealm.h
//  iNaturalistTests
//
//  Created by Alex Shepard on 1/11/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>

#import "ExploreObservationFieldRealm.h"
#import "ExploreProjectObservationField.h"

NS_ASSUME_NONNULL_BEGIN

@interface ExploreProjectObservationFieldRealm : RLMObject

@property NSInteger projectObservationFieldId;
@property NSInteger position;
@property BOOL required;
@property ExploreObservationFieldRealm *observationField;

- (instancetype)initWithMantleModel:(ExploreProjectObservationField *)model;

@end

RLM_ARRAY_TYPE(ExploreProjectObservationFieldRealm)

NS_ASSUME_NONNULL_END
