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

+ (NSDictionary *)valueForCoreDataModel:(id)cdModel {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    
    value[@"obsFieldId"] = [cdModel valueForKey:@"recordID"];
    value[@"name"] = [cdModel valueForKey:@"name"];
    value[@"inatDescription"] = [cdModel valueForKey:@"desc"];
    
    // needs conversion from string to enum type
    NSDictionary *typeMappings = @{
        @"text": @(ExploreObsFieldDataTypeText),
        @"numeric": @(ExploreObsFieldDataTypeNumeric),
        @"date": @(ExploreObsFieldDataTypeDate),
        @"time": @(ExploreObsFieldDataTypeTime),
        @"datetime": @(ExploreObsFieldDataTypeDateTime),
        @"taxon": @(ExploreObsFieldDataTypeTaxon),
        @"dna": @(ExploreObsFieldDataTypeDna),
    };
    if ([typeMappings objectForKey:[cdModel valueForKey:@"datatype"]]) {
        value[@"dataType"] = typeMappings[[cdModel valueForKey:@"datatype"]];
    } else {
        value[@"dataType"] = @(ExploreObsFieldDataTypeText);
    }
    
    // to-many primitive
    if ([cdModel valueForKey:@"allowedValues"]) {
        value[@"allowedValues"] = [[cdModel valueForKey:@"allowedValues"] componentsSeparatedByString:@"|"];
    }
    
    return [NSDictionary dictionaryWithDictionary:value];
}

- (BOOL)canBeTreatedAsText {
    return self.dataType == ExploreObsFieldDataTypeText || self.dataType == ExploreObsFieldDataTypeDna;
}

+ (NSString *)primaryKey {
    return @"obsFieldId";
}

@end
