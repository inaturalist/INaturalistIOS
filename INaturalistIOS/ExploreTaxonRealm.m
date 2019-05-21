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
        
        self.wikipediaUrlString = [taxon.wikipediaUrl absoluteString];
	}
	return self;
}

+ (NSString *)primaryKey {
	return @"taxonId";
}

- (NSURL *)photoUrl {
	return [NSURL URLWithString:self.photoUrlString];
}

- (NSURL *)wikipediaUrl {
    return [NSURL URLWithString:self.wikipediaUrlString];
}

- (NSString *)wikipediaArticleName {
    return [self.wikipediaUrl lastPathComponent];
}

- (BOOL)isGenusOrLower {
	return (self.rankLevel > 0 && self.rankLevel <= 20);
}

- (BOOL)isSpeciesOrLower {
	return (self.rankLevel > 0 && self.rankLevel <= 10);
}

- (NSAttributedString *)wikipediaSummaryAttrStringWithSystemFontSize:(CGFloat)fontSize {
    if (self.webContent.length == 0) {
        return nil;
    }
    
    NSString *wikiContent = [self.webContent stringByStrippingHTML];
    NSString *attributionAnchor = [NSString stringWithFormat:@"<a href=\"%@\">%@</a>",
                                   self.wikipediaUrlString, self.wikipediaArticleName];
    NSString *licenseAnchor = @"<a href=\"https://creativecommons.org/licenses/by-sa/3.0/\">CC BY-SA 3.0</a>";
    NSString *htmlStyle = [NSString stringWithFormat:@"<style>p{font-family: '-apple-system';font-size: %f;}</style>",
                           fontSize];
    
    NSString *attributionFormatStr = NSLocalizedString(@"Source: Wikipedia, %1$@, %2$@", @"credit for the wikipedia snippet that we include in inat taxon pages. first substitution is the article name, the second substitution is the license name.");
    
    NSString *wikiAttribution = [NSString stringWithFormat:attributionFormatStr,
                                 attributionAnchor, licenseAnchor];
    NSString *wikiText = [NSString stringWithFormat:@"<p>%@ (%@)</p>%@",
                          wikiContent, wikiAttribution, htmlStyle];
    NSData *wikiTextData = [wikiText dataUsingEncoding:NSUTF8StringEncoding];
    
    return [[NSAttributedString alloc] initWithData:wikiTextData
                                            options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                      NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                 documentAttributes:nil
                                              error:nil];

}

@end
