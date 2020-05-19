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

+ (NSDictionary *)valueForCoreDataModel:(id)model {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    
    value[@"taxonPhotoId"] = [model valueForKey:@"recordID"];
    value[@"attribution"] = [model valueForKey:@"attribution"];
    value[@"urlString"] = [model valueForKey:@"squareURL"];
    value[@"licenseCode"] = [model valueForKey:@"licenseCode"];
    
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

- (NSString *)urlStringForSize:(NSString *)size {
    return [self.urlString stringByReplacingOccurrencesOfString:@"square" withString:size];
}

@end
