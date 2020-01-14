//
//  ExploreObsFieldRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 1/14/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>
#import "ExploreObsField.h"

@interface ExploreObsFieldRealm : RLMObject

@property RLMArray<RLMString> *allowedValues;
@property NSString *name;
@property NSString *inatDescription;
@property NSInteger obsFieldId;
@property ExploreObsFieldDataType dataType;

- (instancetype)initWithMantleModel:(ExploreObsField *)model;
+ (NSDictionary *)valueForMantleModel:(ExploreObsField *)model;

@end
