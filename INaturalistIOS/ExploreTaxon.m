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
        @"wikipediaUrl": @"wikipedia_url",
	};
}

+ (NSValueTransformer *)photoUrlJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)wikipediaUrlJSONTransformer {
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

- (NSString *)wikipediaArticleName {
    return [self.wikipediaUrl lastPathComponent];
}


- (NSString *)displayFirstName {
    if (!self.commonName) {
        return [self displayScientificName];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:kINatShowCommonNamesPrefKey]) {
        if ([defaults boolForKey:kINatShowScientificNamesFirstPrefKey]) {
            return [self displayScientificName];
        } else {
            return self.commonName;
        }
    } else {
        return [self displayScientificName];
    }
}

- (BOOL)displayFirstNameIsItalicized {
    return [self nameIsItalicized:self.displayFirstName];
}

- (NSString *)displaySecondName {
    if (!self.commonName) { return nil; }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:kINatShowCommonNamesPrefKey]) {
        if ([defaults boolForKey:kINatShowScientificNamesFirstPrefKey]) {
            return self.commonName;
        } else {
            return [self displayScientificName];
        }
    } else {
        return nil;
    }
}

- (BOOL)displaySecondNameIsItalicized {
    return [self nameIsItalicized:self.displaySecondName];
}

- (BOOL)nameIsItalicized:(NSString *)name {
    if ([name isEqualToString:self.scientificName] && self.rankLevel > 0 && self.rankLevel <= 20) {
        return YES;
    } else {
        return NO;
    }
}

- (NSString *)displayScientificName {
    if (self.rankLevel > 20) {
        NSString *localizedRankName = NSLocalizedStringFromTable(self.rankName, @"TaxaRanks", nil);
        return [NSString stringWithFormat:@"%@ %@", [localizedRankName localizedCapitalizedString], self.scientificName];
    } else {
        return self.scientificName;
    }
}

@end
