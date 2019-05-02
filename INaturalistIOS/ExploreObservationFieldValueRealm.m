//
//  ExploreObservationFieldValueRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/12/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import "ExploreObservationFieldValueRealm.h"

@implementation ExploreObservationFieldValueRealm

- (instancetype)initWithMantleModel:(ExploreObservationFieldValue *)model {
    if (self = [super init]) {
        self.fieldId = model.fieldId;
        self.uuid = model.uuid;
        self.value = model.value;
    }
    
    return self;
}

+ (NSString *)primaryKey {
    return @"uuid";
}

@end
