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

@end
