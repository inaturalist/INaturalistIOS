//
//  ExploreIdentificationRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 8/9/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ExploreIdentificationRealm.h"
#import "ExploreIdentification.h"
#import "ExploreUserRealm.h"
#import "ExploreTaxonRealm.h"

@implementation ExploreIdentificationRealm

- (instancetype)initWithMantleModel:(ExploreIdentification *)model {
	if (self = [super init]) {
		self.identificationId = model.identificationId;
		self.identificationBody = model.identificationBody;
		self.identificationIsCurrent = model.identificationIsCurrent;
		self.identifiedDate = model.identifiedDate;
		
		self.identifier = [[ExploreUserRealm alloc] initWithMantleModel:model.identifier];
		self.taxon = [[ExploreTaxonRealm alloc] initWithMantleModel:model.taxon];
	}
	
	return self;
}

#pragma mark - IdentificationVisualization & ActivityVisualization

- (BOOL)isCurrent {
    return self.identificationIsCurrent;
}

- (NSDate *)date {
    return self.identifiedDate;
}

- (NSDate *)createdAt {
    return self.identifiedDate;
}

- (NSString *)userName {
    return self.identifier.login;
}

- (NSInteger)userId {
    return self.identifier.userId;
}

- (NSURL *)userIconUrl {
    return self.identifier.userIcon;
}

- (NSString *)body {
    return self.identificationBody;
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

- (NSString *)taxonIconicName {
    return self.taxon.iconicTaxonName;
}

- (NSString *)taxonScientificName {
    return self.taxon.scientificName;
}

- (NSString *)taxonCommonName {
    return self.taxon.commonName;
}

- (NSURL *)taxonIconUrl {
    return self.taxon.photoUrl;
}

@end
