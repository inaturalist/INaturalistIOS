//
//  ExploreIdentification.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/10/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreIdentification.h"
#import "ExploreTaxon.h"
#import "ExploreModeratorAction.h"
#import "ExploreUser.h"

@implementation ExploreIdentification

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
		@"identificationId": @"id",
		@"identificationIsCurrent": @"current",
		@"identificationBody": @"body",
		@"taxon": @"taxon",
		@"identifiedDate": @"created_at",
		@"identifier": @"user",
        @"hidden": @"hidden",
        @"moderatorActions": @"moderator_actions",
	};
}

+ (NSValueTransformer *)identifierJSONTransformer {
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ExploreUser.class];
}

+ (NSValueTransformer *)taxonJSONTransformer {
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ExploreTaxon.class];
}

+ (NSValueTransformer *)identifiedDateJSONTransformer {
    static NSISO8601DateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSISO8601DateFormatter alloc] init];
    });

    return [MTLValueTransformer transformerWithBlock:^id(id dateString) {
        return [_dateFormatter dateFromString:dateString];
    }];
}

+ (NSValueTransformer *)moderatorActionsJSONTransformer {
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:ExploreModeratorAction.class];
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

- (NSDate *)moderationDate {
    ExploreModeratorAction *a = [self.moderatorActions firstObject];
    if (a) {
        return a.date;
    } else {
        return nil;
    }
}

- (NSString *)moderationReason {
    ExploreModeratorAction *a = [self.moderatorActions firstObject];
    if (a) {
        return a.reason;
    } else {
        return nil;
    }
}

- (NSString *)moderatorUsername {
    ExploreModeratorAction *a = [self.moderatorActions firstObject];
    if (a) {
        return a.user.login;
    } else {
        return nil;
    }
}


@end
