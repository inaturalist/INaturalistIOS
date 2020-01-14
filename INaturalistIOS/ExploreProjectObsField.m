//
//  ExploreProjectObsField.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/13/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import "ExploreProjectObsField.h"

#import "ExploreObsField.h"

@implementation ExploreProjectObsField

+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{
        @"required": @"required",
        @"position": @"position",
        @"projectObsFieldId": @"id",
        @"obsField": @"observation_field",
    };
}

- (void)setNilValueForKey:(NSString *)key {
    if ([key isEqualToString:@"required"]) {
        self.required = FALSE;
    } else if ([key isEqualToString:@"position"]) {
        self.position = 0;
    }
}

+ (NSValueTransformer *)obsFieldJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ExploreObsField.class];
}


@end
