//
//  ExploreProjectObservationRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 5/28/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>

#import "ExploreProjectObservation.h"

@interface ExploreProjectObservationRealm : RLMObject

@property NSInteger recordId;
@property NSString *uuid;
@property NSInteger projectId;

- (instancetype)initWithMantleModel:(ExploreProjectObservation *)model;

@property (readonly) RLMLinkingObjects *observations;

@end

RLM_ARRAY_TYPE(ExploreProjectObservationRealm)
