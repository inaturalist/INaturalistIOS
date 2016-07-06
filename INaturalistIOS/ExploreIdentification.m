//
//  ExploreIdentification.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/10/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreIdentification.h"
#import "ExploreUser.h"
#import "ExploreTaxon.h"

@implementation ExploreIdentification

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
		@"identificationId": @"id",
		@"identificationIsCurrent": @"current",
		@"identificationBody": @"body",
		@"taxon": @"taxon",
		@"identifiedDate": @"created_at",
		@"identifier": @"user",
	};
}

+ (NSValueTransformer *)identifierJSONTransformer {
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ExploreUser.class];
}

+ (NSValueTransformer *)taxonJSONTransformer {
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ExploreTaxon.class];
}

+ (NSValueTransformer *)identifiedDateJSONTransformer {
	static NSDateFormatter *_dateFormatter = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_dateFormatter = [[NSDateFormatter alloc] init];
		_dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
		_dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
	});

    return [MTLValueTransformer transformerWithBlock:^id(id dateString) {
        return [_dateFormatter dateFromString:dateString];
    }];
}

#pragma mark - ActivityVisualziation

- (NSDate *)createdAt {
    return self.identifiedDate;
}

#pragma mark - IdentificationVisualization

- (NSInteger)userId {
    return self.identifier.userId;
}

- (NSString *)body {
    return self.identificationBody;
}

- (NSDate *)date {
    return self.identifiedDate;
}

- (NSString *)userName {
    return self.identifier.login;
}

- (NSURL *)userIconUrl {
	return self.identifier.userIcon;
}

- (NSString *)taxonCommonName {
    return self.taxon.commonName;
}

- (NSString *)taxonScientificName {
    return self.taxon.scientificName;
}

- (NSString *)taxonIconicName {
	return self.taxon.iconicTaxonName;
}

- (NSInteger)taxonId {
    return self.taxon.taxonId;
}

- (NSInteger)taxonRankLevel {
    return self.taxon.rankLevel;
}

- (NSString *)taxonRank {
    return self.taxon.rankName;
}

- (NSURL *)taxonIconUrl {
	return self.taxon.photoUrl;
}

- (BOOL)isCurrent {
    return self.identificationIsCurrent;
}

@end
