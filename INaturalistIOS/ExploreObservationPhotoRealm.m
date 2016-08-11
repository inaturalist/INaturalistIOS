//
//  ExploreObservationPhotoRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 8/9/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ExploreObservationPhotoRealm.h"
#import "ExploreObservationPhoto.h"

@implementation ExploreObservationPhotoRealm

- (instancetype)initWithMantleModel:(ExploreObservationPhoto *)model {
	if (self = [super init]) {
		self.url = model.url;	
	}
	
	return self;
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

- (NSString *)urlStringForSize:(NSString *)size {
    return [self.url stringByReplacingOccurrencesOfString:@"square" withString:size];
}

@end
