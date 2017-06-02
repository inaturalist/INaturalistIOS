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
        self.nativePageUrlString = [model.nativePageUrl absoluteString];
        self.squareUrlString = [model.squareUrl absoluteString];
        self.smallUrlString = [model.smallUrl absoluteString];
        self.mediumUrlString = [model.mediumUrl absoluteString];
        self.largeUrlString = [model.mediumUrl absoluteString];
    }
    
    return self;
}

+ (NSString *)primaryKey {
    return @"taxonPhotoId";
}


- (NSURL *)nativePageUrl {
    return [NSURL URLWithString:self.nativePageUrlString];
}

- (NSURL *)squareUrl {
    return [NSURL URLWithString:self.squareUrlString];
}

- (NSURL *)smallUrl {
    return [NSURL URLWithString:self.smallUrlString];
}

- (NSURL *)mediumUrl {
    return [NSURL URLWithString:self.mediumUrlString];
}

- (NSURL *)largeUrl {
    return [NSURL URLWithString:self.largeUrlString];
}

@end
