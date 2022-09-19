//
//  ExploreObsField.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/13/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import "ExploreObsField.h"

@implementation ExploreObsField

+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{
        @"allowedValues": @"allowed_values",
        @"name": @"name",
        @"inatDescription": @"description",
        @"obsFieldId": @"id",
        @"dataType": @"datatype",
    };
}

+ (NSValueTransformer *)allowedValuesJSONTransformer {
    return [MTLValueTransformer transformerWithBlock:^id(NSString *allowedValues) {
        return [allowedValues componentsSeparatedByString:@"|"];
    }];
}

+ (NSValueTransformer *)dataTypeJSONTransformer {
    NSDictionary *typeMappings = @{
        @"text": @(ExploreObsFieldDataTypeText),
        @"numeric": @(ExploreObsFieldDataTypeNumeric),
        @"date": @(ExploreObsFieldDataTypeDate),
        @"time": @(ExploreObsFieldDataTypeTime),
        @"datetime": @(ExploreObsFieldDataTypeDateTime),
        @"taxon": @(ExploreObsFieldDataTypeTaxon),
        @"dna": @(ExploreObsFieldDataTypeDna),
    };
    
    return [NSValueTransformer mtl_valueMappingTransformerWithDictionary:typeMappings];
}



@end
