//
//  ExploreTaxonPhotoRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/17/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import "ExploreTaxonPhotoRealm.h"

@implementation ExploreTaxonPhotoRealm

- (instancetype)initWithMantleModel:(ExploreTaxonPhoto *)model {
    if (self = [super init]) {
        self.taxonPhotoId = model.taxonPhotoId;
        self.attribution = model.attribution;
        self.urlString = [model.squareUrl absoluteString];
        self.licenseCode = model.licenseCode;
    }
    
    return self;
}

+ (NSDictionary *)valueForMantleModel:(ExploreTaxonPhoto *)model {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    
    value[@"taxonPhotoId"] = @(model.taxonPhotoId);
    value[@"attribution"] = model.attribution;
    value[@"urlString"] = [model.squareUrl absoluteString];
    value[@"licenseCode"] = model.licenseCode;
    
    return [NSDictionary dictionaryWithDictionary:value];
}

+ (NSDictionary *)valueForCoreDataModel:(id)cdModel {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    
    if ([cdModel valueForKey:@"recordID"]) {
        value[@"taxonPhotoId"] = [cdModel valueForKey:@"recordID"];
    } else {
        // this is not an uploadable, return nil if we don't have a
        // record id
        return nil;
    }
    
    if ([cdModel valueForKey:@"attribution"]) {
        value[@"attribution"] = [cdModel valueForKey:@"attribution"];
    }
    
    if ([cdModel valueForKey:@"squareURL"]) {
        value[@"urlString"] = [cdModel valueForKey:@"squareURL"];
    }
    
    if ([cdModel valueForKey:@"licenseCode"]) {
        value[@"licenseCode"] = [cdModel valueForKey:@"licenseCode"];
    }
    
    return [NSDictionary dictionaryWithDictionary:value];
}


+ (NSString *)primaryKey {
    return @"taxonPhotoId";
}

- (NSURL *)largePhotoUrl {
    return [NSURL URLWithString:[self urlStringForSize:@"large"]];
}

- (NSURL *)mediumPhotoUrl {
    return [NSURL URLWithString:[self urlStringForSize:@"medium"]];
}

- (NSURL *)smallPhotoUrl {
    return [NSURL URLWithString:[self urlStringForSize:@"small"]];
}

- (NSURL *)thumbPhotoUrl {
    return [NSURL URLWithString:[self urlStringForSize:@"thumb"]];
}

- (NSURL *)squarePhotoUrl {
    return [NSURL URLWithString:self.urlString];
}

- (NSString *)photoKey {
    return nil;
}


- (NSString *)urlStringForSize:(NSString *)size {
    return [self.urlString stringByReplacingOccurrencesOfString:@"square" withString:size];
}

@end
