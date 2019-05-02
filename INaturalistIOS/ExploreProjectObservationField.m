//
//  ExploreProjectObservationField.m
//  iNaturalistTests
//
//  Created by Alex Shepard on 1/11/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import "ExploreProjectObservationField.h"

@implementation ExploreProjectObservationField

+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{
             @"projectObservationFieldId": @"id",
             @"position": @"position",
             @"required": @"required",
             @"observationField": @"observation_field",
             };
}

+ (NSValueTransformer *)observationFieldJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ExploreObservationField.class];
}

@end
