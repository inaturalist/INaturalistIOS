//
//  ExploreTaxonRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 6/25/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ExploreTaxonRealm.h"

@implementation ExploreTaxonRealm

- (instancetype)initWithMantleModel:(ExploreTaxon *)taxon {
	if (self = [super init]) {
		self.taxonId = taxon.taxonId;
		self.webContent = taxon.webContent;
		self.commonName = taxon.commonName;
		self.scientificName = taxon.scientificName;
        self.searchableCommonName = [taxon.commonName stringByFoldingWithOptions:NSDiacriticInsensitiveSearch
                                                                           locale:[NSLocale currentLocale]];
        self.searchableScientificName = [taxon.scientificName stringByFoldingWithOptions:NSDiacriticInsensitiveSearch
                                                                                  locale:[NSLocale currentLocale]];
		self.photoUrlString = [taxon.photoUrl absoluteString];
		self.rankName = taxon.rankName;
		self.rankLevel = taxon.rankLevel;
		self.iconicTaxonName = taxon.iconicTaxonName;
		self.lastMatchedTerm = taxon.matchedTerm;
        self.searchableLastMatchedTerm = [taxon.matchedTerm stringByFoldingWithOptions:NSDiacriticInsensitiveSearch
                                                                          		locale:[NSLocale currentLocale]];
        self.observationCount = taxon.observationCount;
        
        for (ExploreTaxonPhoto *etp in [taxon taxonPhotos]) {
            ExploreTaxonPhotoRealm *etpr = [[ExploreTaxonPhotoRealm alloc] initWithMantleModel:etp];
            [self.taxonPhotos addObject:etpr];
        }
	}
	return self;
}

+ (NSString *)primaryKey {
	return @"taxonId";
}

- (NSURL *)photoUrl {
	return [NSURL URLWithString:self.photoUrlString];
}

- (BOOL)isGenusOrLower {
	return (self.rankLevel > 0 && self.rankLevel <= 20);
}

- (BOOL)isSpeciesOrLower {
	return (self.rankLevel > 0 && self.rankLevel <= 10);
}

@end
