//
//  ExploreProjectObservationRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/28/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import "ExploreProjectObservationRealm.h"
#import "ExploreObservationRealm.h"

@implementation ExploreProjectObservationRealm

- (instancetype)initWithMantleModel:(ExploreProjectObservation *)model {
    if (self = [super init]) {
        self.recordId = model.recordId;
        self.uuid = model.uuid;
        self.projectId = model.projectId;
    }
    
    return self;
}

+ (NSDictionary *)linkingObjectsProperties {
    return @{
             @"observations": [RLMPropertyDescriptor descriptorWithClass:ExploreObservationRealm.class
                                                            propertyName:@"projectObservations"]
             };
}


@end
