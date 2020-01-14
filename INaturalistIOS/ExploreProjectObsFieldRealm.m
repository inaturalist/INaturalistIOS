//
//  ExploreProjectObsFieldRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/14/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import "ExploreProjectObsFieldRealm.h"

@implementation ExploreProjectObsFieldRealm

/*
@property BOOL required;
@property NSInteger position;
@property NSInteger projectObsFieldId;
@property ExploreObsFieldRealm *obsField;
*/

- (instancetype)initWithMantleModel:(ExploreProjectObsField *)model {
    if (self = [super init]) {
        self.required = model.required;
        self.position = model.position;
        self.projectObsFieldId = model.projectObsFieldId;
        if (model.obsField) {
            self.obsField = [[ExploreObsFieldRealm alloc] initWithMantleModel:model.obsField];
        }
    }
    
    return self;
}

+ (NSDictionary *)valueForMantleModel:(ExploreProjectObsField *)model {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    
    value[@"required"] = @(model.required);
    value[@"position"] = @(model.position);
    value[@"projectObsFieldId"] = @(model.projectObsFieldId);
    if (model.obsField) {
        value[@"obsField"] = [ExploreObsFieldRealm valueForMantleModel:model.obsField];
    }
    
    return [NSDictionary dictionaryWithDictionary:value];
}

+ (NSString *)primaryKey {
    return @"projectObsFieldId";
}

@end
