//
//  ExploreProjectObservationFieldRealm.m
//  iNaturalistTests
//
//  Created by Alex Shepard on 1/11/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import "ExploreProjectObservationFieldRealm.h"

@implementation ExploreProjectObservationFieldRealm

- (instancetype)initWithMantleModel:(ExploreProjectObservationField *)model {
    if (self = [super init]) {
        self.projectObservationFieldId = model.projectObservationFieldId;
        self.position = model.position;
        self.required = model.required;
        
        if (model.observationField) {
            self.observationField = [[ExploreObservationFieldRealm alloc] initWithMantleModel:model.observationField];
        }
    }
    
    return self;
}

+ (NSString *)primaryKey {
    return @"projectObservationFieldId";
}

@end
