//
//  ExploreObsFieldValue.m
//  iNaturalist
//
//  Created by Alex Shepard on 4/21/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import "ExploreObsFieldValue.h"
#import "ExploreObsField.h"

@implementation ExploreObsFieldValue

+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{
        @"obsFieldValueId": @"id",
        @"value": @"value",
        @"obsField": @"observation_field",
        @"uuid": @"uuid",
    };
}

+ (NSValueTransformer *)obsFieldJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ExploreObsField.class];
}

@end
