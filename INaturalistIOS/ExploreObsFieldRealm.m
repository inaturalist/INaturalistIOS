//
//  ExploreObsFieldRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/14/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import "ExploreObsFieldRealm.h"

@implementation ExploreObsFieldRealm

- (instancetype)initWithMantleModel:(ExploreObsField *)model {
    if (self = [super init]) {
        [self.allowedValues addObjects:model.allowedValues];
        self.name = model.name;
        self.inatDescription = model.inatDescription;
        self.obsFieldId = model.obsFieldId;
        self.dataType = model.dataType;
    }
    
    return self;    
}

+ (NSDictionary *)valueForMantleModel:(ExploreObsField *)model {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    
    if (model.allowedValues) { value[@"allowedValues"] = model.allowedValues; }
    if (model.name) { value[@"name"] = model.name; }
    if (model.inatDescription) { value[@"inatDescription"] = model.inatDescription; }
    value[@"obsFieldId"] = @(model.obsFieldId);
    value[@"dataType"] = @(model.dataType);
    
    return [NSDictionary dictionaryWithDictionary:value];
}

+ (NSString *)primaryKey {
    return @"obsFieldId";
}

@end
