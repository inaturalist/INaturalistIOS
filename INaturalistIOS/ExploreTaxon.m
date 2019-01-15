//
//  ExploreTaxon.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/13/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreTaxon.h"
#import "ExploreTaxonPhoto.h"

@implementation ExploreTaxon

+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{
		@"taxonId": @"id",
		@"webContent": @"wikipedia_summary",
		@"commonName": @"preferred_common_name",
		@"scientificName": @"name",
		@"photoUrl": @"default_photo.square_url",
		@"rankName": @"rank",
		@"rankLevel": @"rank_level",
		@"iconicTaxonName": @"iconic_taxon_name",
		@"matchedTerm": @"matched_term",
		@"observationCount": @"observations_count",
        @"taxonPhotos": @"taxon_photos",
	};
}

+ (NSValueTransformer *)photoUrlJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)taxonPhotosJSONTransformer {
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:ExploreTaxonPhoto.class];
}

- (BOOL)isGenusOrLower {
	return (self.rankLevel > 0 && self.rankLevel <= 20);
}

- (void)setNilValueForKey:(NSString *)key {
    if ([key isEqualToString:@"rankLevel"]) {
        self.rankLevel = 0;
    } else if ([key isEqualToString:@"observationCount"]) {
    	self.observationCount = 0;
    } else {
        [super setNilValueForKey:key];
    }
}

@end
