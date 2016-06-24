//
//  ExploreTaxon.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/13/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreTaxon.h"

@implementation ExploreTaxon

+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{
		@"taxonId": @"id",
		@"webContent": @"body",
		@"commonName": @"preferred_common_name",
		@"scientificName": @"name",
		@"photoUrl": @"default_photo.square_url",
		@"rankName": @"rank",
		@"rankLevel": @"rank_level",
		@"iconicTaxonName": @"iconic_taxon_name",
	};
}

- (BOOL)isGenusOrLower {
	return (self.rankLevel > 0 && self.rankLevel <= 20);
}

@end
