//
//  ExploreProjectObsFieldRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 1/14/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

@import Realm;

#import "ExploreObsFieldRealm.h"
#import "ExploreProjectObsField.h"

@class ExploreProjectRealm;

@interface ExploreProjectObsFieldRealm : RLMObject

@property BOOL required;
@property NSInteger position;
@property NSInteger projectObsFieldId;
@property ExploreObsFieldRealm *obsField;

@property (readonly) ExploreProjectRealm *project;

- (instancetype)initWithMantleModel:(ExploreProjectObsField *)model;
+ (NSDictionary *)valueForMantleModel:(ExploreProjectObsField *)model;
+ (NSDictionary *)valueForCoreDataModel:(id)model;

@end

RLM_ARRAY_TYPE(ExploreProjectObsFieldRealm)
