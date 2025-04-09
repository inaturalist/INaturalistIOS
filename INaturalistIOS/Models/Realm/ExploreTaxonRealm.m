//
//  ExploreTaxonRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 6/25/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ExploreTaxonRealm.h"
#import "GuideTaxonXML.h"

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
        self.searchableLastMatchedTerm = [[ExploreTaxonRealm class] cleanedSearchMatchTermFor:taxon.matchedTerm];
        self.observationCount = taxon.observationCount;
        self.isActive = taxon.isActive;
        self.representativePhotoUrlString = [taxon.representativePhotoUrl absoluteString];
        for (ExploreTaxonPhoto *etp in [taxon taxonPhotos]) {
            ExploreTaxonPhotoRealm *etpr = [[ExploreTaxonPhotoRealm alloc] initWithMantleModel:etp];
            [self.taxonPhotos addObject:etpr];
        }
        
        self.wikipediaUrlString = [taxon.wikipediaUrl absoluteString];
	}
	return self;
}

+ (NSString *)cleanedSearchMatchTermFor:(NSString *)term {
    NSString *t = [term stringByFoldingWithOptions:NSDiacriticInsensitiveSearch
                                            locale:[NSLocale currentLocale]];
    t = [t stringByReplacingOccurrencesOfString:@"-" withString:@" "];
    return t;
}

+ (NSDictionary *)valueForMantleModel:(ExploreTaxon *)model {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    
    value[@"taxonId"] = @(model.taxonId);
    value[@"webContent"] = model.webContent;
    value[@"commonName"] = model.commonName;
    value[@"scientificName"] = model.scientificName;
    value[@"searchableCommonName"] = [model.commonName stringByFoldingWithOptions:NSDiacriticInsensitiveSearch
                                                                           locale:[NSLocale currentLocale]];
    value[@"searchableScientificName"] = [model.scientificName stringByFoldingWithOptions:NSDiacriticInsensitiveSearch
                                                                                   locale:[NSLocale currentLocale]];
    value[@"photoUrlString"] = [model.photoUrl absoluteString];
    value[@"representativePhotoUrlString"] = [model.representativePhotoUrl absoluteString];

    value[@"rankName"] = model.rankName;
    value[@"rankLevel"] = @(model.rankLevel);
    value[@"iconicTaxonName"] = model.iconicTaxonName;
    value[@"lastMatchedTerm"] = model.matchedTerm;
    value[@"searchableLastMatchedTerm"] = [[ExploreTaxonRealm class] cleanedSearchMatchTermFor:model.matchedTerm];
    value[@"observationCount"] = @(model.observationCount);
    value[@"isActive"] = @(model.isActive);
    
    if (model.taxonPhotos) {
        NSMutableArray *etprs = [NSMutableArray array];
        for (ExploreTaxonPhoto *etp in model.taxonPhotos) {
            [etprs addObject:[ExploreTaxonPhotoRealm valueForMantleModel:etp]];
        }
        value[@"taxonPhotos"] = [NSArray arrayWithArray:etprs];
    }

    value[@"wikipediaUrlString"] = model.wikipediaUrl.absoluteString;
    
    return [NSDictionary dictionaryWithDictionary:value];
}

+ (NSDictionary *)valueForRealmModel:(ExploreTaxonRealm *)model {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    RLMObjectSchema *schema = model.objectSchema;
    for (RLMProperty *property in schema.properties) {
       dict[property.name] = model[property.name];
    }
    return [NSDictionary dictionaryWithDictionary:dict];
}

+ (NSDictionary *)valueForCoreDataModel:(id)cdModel {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    
    if ([cdModel valueForKey:@"recordID"]) {
        value[@"taxonId"] = [cdModel valueForKey:@"recordID"];
    } else {
        // this is not an uploadable, return nil if we don't have a
        // record id
        return nil;
    }
    
    if ([cdModel valueForKey:@"rankLevel"]) {
        value[@"rankLevel"] = [cdModel valueForKey:@"rankLevel"];
    } else {
        value[@"rankLevel"] = @(0);
    }
    
    // migrate with observation count of zero, since it's only used
    // for sorting and will be refreshed from the server anyways.
    // for some reason, it wasn't migrating correctly sometimes.
    value[@"observationCount"] = @(0);
    
    // migrate with isActive true, since it should be refreshed
    // by the server.
    value[@"isActive"] = @(YES);
    
    if ([cdModel valueForKey:@"defaultName"]) {
        value[@"commonName"] = [cdModel valueForKey:@"defaultName"];
        value[@"searchableCommonName"] = [[cdModel valueForKey:@"defaultName"] stringByFoldingWithOptions:NSDiacriticInsensitiveSearch
                                                                                                   locale:[NSLocale currentLocale]];
    }
    
    if ([cdModel valueForKey:@"name"]) {
        value[@"scientificName"] = [cdModel valueForKey:@"name"];
        value[@"searchableScientificName"] = [[cdModel valueForKey:@"name"] stringByFoldingWithOptions:NSDiacriticInsensitiveSearch
                                                                                                locale:[NSLocale currentLocale]];
    }
    
    if ([cdModel valueForKey:@"rankName"]) {
        value[@"rankName"] = [cdModel valueForKey:@"rankName"];
    }
    
    if ([cdModel valueForKey:@"wikipediaSummary"]) {
        value[@"webContent"] = [cdModel valueForKey:@"wikipediaSummary"];
    }
    
    
    if ([cdModel valueForKey:@"taxonPhotos"]) {
        NSMutableArray *photosValue = [NSMutableArray array];
        for (id cdPhoto in [cdModel valueForKey:@"taxonPhotos"]) {
            id photoValue = [ExploreTaxonPhotoRealm valueForCoreDataModel:cdPhoto];
            if (photoValue) {
                [photosValue addObject:photoValue];
            }
        }
        if (photosValue.count > 0) {
            value[@"taxonPhotos"] = [NSArray arrayWithArray:photosValue];
        }
    }
    
    return [NSDictionary dictionaryWithDictionary:value];
}

+ (NSString *)primaryKey {
	return @"taxonId";
}

- (NSURL *)photoUrl {
	return [NSURL URLWithString:self.photoUrlString];
}

- (NSURL *)representativePhotoUrl {
    return [NSURL URLWithString:self.representativePhotoUrlString];
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

- (BOOL)scientificNameIsItalicized {
    // everything at genus and below EXCEPT complex
    if ((self.rankLevel != 11) && (self.rankLevel > 0 && self.rankLevel <= 20)) {
        return YES;
    } else {
        return NO;
    }
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
    if ([name containsString:self.scientificName] && self.rankLevel > 0 && self.rankLevel <= 20) {
        return YES;
    } else {
        return NO;
    }
}

- (NSString *)displayScientificName {
    if (self.rankLevel > 10) {
        NSString *localizedRankName = NSLocalizedStringFromTable(self.rankName, @"TaxaRanks", nil);
        return [NSString stringWithFormat:@"%@ %@", [localizedRankName localizedCapitalizedString], self.scientificName];
    } else {
        return self.scientificName;
    }
}

+ (NSArray<NSString *> *)ignoredProperties {
    return @[
        @"representativePhotoUrlString",
    ];
}


@end
