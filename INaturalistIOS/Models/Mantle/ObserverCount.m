
//
//  ObserverCount.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ObserverCount.h"
#import "ExploreUser.h"

@implementation ObserverCount


+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{
		@"observer": @"user",
		@"observationCount": @"observation_count",
		@"speciesCount": @"species_count",
	};
}

+ (NSValueTransformer *)observerJSONTransformer {
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ExploreUser.class];
}

@end
