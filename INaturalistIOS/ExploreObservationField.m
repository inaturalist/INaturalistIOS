//
//  ExploreObservationField.m
//  iNaturalistTests
//
//  Created by Alex Shepard on 1/11/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import "ExploreObservationField.h"

@implementation ExploreObservationField

+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{
             @"fieldId": @"id",
             @"dataType": @"datatype",
             @"name": @"name",
             @"inatDescription": @"description",
             @"allowedValues": @"allowed_values",
             };
}

+ (NSValueTransformer *)allowedValuesJSONTransformer {
    return [MTLValueTransformer transformerWithBlock:^id(id allowedValues) {
        NSString *allowedValuesString = (NSString *)allowedValues;
        return [allowedValuesString componentsSeparatedByString:@"|"];
    }];
}


@end
