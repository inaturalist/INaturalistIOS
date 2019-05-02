//
//  ExploreObservationFieldRealm.h
//  iNaturalistTests
//
//  Created by Alex Shepard on 1/11/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>

#import "ExploreObservationField.h"

NS_ASSUME_NONNULL_BEGIN

@interface ExploreObservationFieldRealm : RLMObject

@property NSInteger fieldId;
@property RLMArray <RLMString> *allowedValues;
@property NSString *dataType;
@property NSString *name;
@property NSString *inatDescription;

- (instancetype)initWithMantleModel:(ExploreObservationField *)model;

@end

NS_ASSUME_NONNULL_END
