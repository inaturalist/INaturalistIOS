//
//  ExploreObservationFieldRealm.m
//  iNaturalistTests
//
//  Created by Alex Shepard on 1/11/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import "ExploreObservationFieldRealm.h"

@implementation ExploreObservationFieldRealm

- (instancetype)initWithMantleModel:(ExploreObservationField *)model {
    if (self = [super init]) {
        self.fieldId = model.fieldId;
        self.dataType = model.dataType;
        self.name = model.name;
        self.inatDescription = model.inatDescription;
        
        for (NSString *allowedValue in model.allowedValues) {
            [self.allowedValues addObject:allowedValue];
        }
    }
    
    return self;
}

+ (NSString *)primaryKey {
    return @"fieldId";
}


@end
