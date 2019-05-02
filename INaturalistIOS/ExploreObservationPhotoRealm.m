//
//  ExploreObservationPhotoRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/12/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import "ExploreObservationPhotoRealm.h"

@implementation ExploreObservationPhotoRealm

- (instancetype)initWithMantleModel:(ExploreObservationPhoto *)model {
    if (self = [super init]) {
        self.observationPhotoId = model.observationPhotoId;
        self.position = model.position;
        self.uuid = model.uuid;
        self.licenseCode = model.licenseCode;
        self.urlString = model.url.absoluteString;
        self.attribution = model.attribution;
        self.photoKey = nil;
    }
    
    return self;
}

+ (NSString *)primaryKey {
    return @"uuid";
}

- (NSURL *)url {
    return [NSURL URLWithString:self.urlString];
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
    return self.url;
}

- (NSString *)urlStringForSize:(NSString *)size {
    return [self.urlString stringByReplacingOccurrencesOfString:@"square"
                                                     withString:size];
}

@end
