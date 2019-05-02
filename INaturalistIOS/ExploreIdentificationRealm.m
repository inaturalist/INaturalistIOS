//
//  ExploreIdentificationRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/17/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ExploreIdentificationRealm.h"

@implementation ExploreIdentificationRealm

- (instancetype)initWithMantleModel:(ExploreIdentification *)model {
    if (self = [super init]) {
        self.identificationId = model.identificationId;
        self.identificationBody = model.identificationBody;
        self.identificationIsCurrent = model.identificationIsCurrent;
        self.identifiedDate = model.identifiedDate;
        
        if (model.identifier) {
            self.identifier = [[ExploreUserRealm alloc] initWithMantleModel:model.identifier];
        }
        
        if (model.taxon) {
            self.taxon = [[ExploreTaxonRealm alloc] initWithMantleModel:model.taxon];
        }

    }
    return self;
}

+ (NSString *)primaryKey {
    return @"identificationId";
}

- (NSString *)body {
    return self.identificationBody;
}

- (NSDate *)createdAt {
    return self.identifiedDate;
}

- (NSURL *)userIconUrl {
    return self.identifier.userIcon;
}

- (NSInteger)userId {
    return self.identifier.userId;
}

- (NSString *)userName {
    return self.identifier.login;
}

- (NSDate *)date {
    return self.identifiedDate;
}

- (BOOL)isCurrent {
    return self.identificationIsCurrent;
}

- (NSString *)taxonCommonName {
    return self.taxon.commonName;
}

- (NSURL *)taxonIconUrl {
    return self.taxon.photoUrl;
}

- (NSString *)taxonIconicName {
    return self.taxon.iconicTaxonName;
}

- (NSInteger)taxonId {
    return self.taxon.taxonId;
}

- (NSString *)taxonRank {
    return self.taxon.rankName;
}

- (NSInteger)taxonRankLevel {
    return self.taxon.rankLevel;
}

- (NSString *)taxonScientificName {
    return self.taxon.scientificName;
}

@end
