//
//  ExploreProjectObservation.m
//  iNaturalist
//
//  Created by Alex Shepard on 4/21/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import "ExploreProjectObservation.h"

@implementation ExploreProjectObservation

+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{
             @"projectObsId": @"id",
             @"uuid": @"uuid",
             @"project": @"project",
             };
}

+ (NSValueTransformer *)projectJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ExploreProject.class];
}


@end
