//
//  IdentifierCount.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "IdentifierCount.h"
#import "ExploreUser.h"

@implementation IdentifierCount

+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{
             @"identifier": @"user",
             @"identificationCount": @"count",
             };
}


+ (NSValueTransformer *)identifierJSONTransformer {
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ExploreUser.class];
}

@end
