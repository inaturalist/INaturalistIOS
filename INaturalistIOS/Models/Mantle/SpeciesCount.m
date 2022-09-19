//
//  SpeciesCount.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "SpeciesCount.h"
#import "ExploreTaxon.h"

@implementation SpeciesCount

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
		@"taxon": @"taxon",
		@"speciesCount": @"count",
	};
}

+ (NSValueTransformer *)taxonJSONTransformer {
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ExploreTaxon.class];
}

- (BOOL)isGenusOrLower
{
	return (self.taxon.rankLevel > 0 && self.taxon.rankLevel <= 20);
}

@end
