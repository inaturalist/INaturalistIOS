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

+ (NSDictionary *)valueForMantleModel:(ExploreIdentification *)model {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    
    value[@"identificationId"] = @(model.identificationId);
    value[@"identificationBody"] = model.identificationBody;
    value[@"identificationIsCurrent"] = @(model.identificationIsCurrent);
    value[@"identifiedDate"] = model.identifiedDate;

    if (model.identifier) {
        value[@"identifier"] = [ExploreUserRealm valueForMantleModel:model.identifier];
    }
    
    if (model.taxon) {
        value[@"taxon"] = [ExploreTaxonRealm valueForMantleModel:model.taxon];
    }
    
    return [NSDictionary dictionaryWithDictionary:value];
}

+ (NSDictionary *)valueForCoreDataModel:(id)cdModel {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    
    if ([cdModel valueForKey:@"recordID"]) {
        value[@"identificationId"] = [cdModel valueForKey:@"recordID"];
    } else {
        value[@"identificationId"] = @(0);
    }
    
    value[@"identificationIsCurrent"] = [cdModel valueForKey:@"current"];
    value[@"identifiedDate"] = [cdModel valueForKey:@"createdAt"];
    value[@"identificationBody"] = [cdModel valueForKey:@"body"];

    if ([cdModel valueForKey:@"user"]) {
        value[@"user"] = [ExploreUserRealm valueForCoreDataModel:[cdModel valueForKey:@"user"]];
    }
    
    if ([cdModel valueForKey:@"taxon"]) {
        value[@"taxon"] = [ExploreTaxonRealm valueForCoreDataModel:[cdModel valueForKey:@"taxon"]];
    }
    
    return [NSDictionary dictionaryWithDictionary:value];
}

+ (NSString *)primaryKey {
    return @"identificationId";
}

#pragma mark - IdentificationVisualization

- (NSDate *)createdAt {
    return self.identifiedDate;
}

- (NSString *)body {
    return self.identificationBody;
}

- (NSDate *)date {
    return self.identifiedDate;
}

- (BOOL)isCurrent {
    return self.identificationIsCurrent;
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

- (NSString *)taxonCommonName {
    return self.taxon.commonName;
}

- (NSString *)taxonScientificName {
    return self.taxon.scientificName;
}

- (NSString *)taxonIconicName {
    return self.taxon.iconicTaxonName;
}

- (NSURL *)taxonIconUrl {
    return self.taxon.photoUrl;
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

@end
