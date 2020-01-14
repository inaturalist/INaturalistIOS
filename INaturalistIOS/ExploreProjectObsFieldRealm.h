//
//  ExploreProjectObsFieldRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 1/14/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>
#import "ExploreObsFieldRealm.h"
#import "ExploreProjectObsField.h"

@interface ExploreProjectObsFieldRealm : RLMObject

@property BOOL required;
@property NSInteger position;
@property NSInteger projectObsFieldId;
@property ExploreObsFieldRealm *obsField;

- (instancetype)initWithMantleModel:(ExploreProjectObsField *)model;
+ (NSDictionary *)valueForMantleModel:(ExploreProjectObsField *)model;

@end

RLM_ARRAY_TYPE(ExploreProjectObsFieldRealm)
