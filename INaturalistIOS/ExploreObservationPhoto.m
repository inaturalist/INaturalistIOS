//
//  ExploreObservationPhoto.m
//  Explore Prototype
//
//  Created by Alex Shepard on 9/9/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreObservationPhoto.h"

@implementation ExploreObservationPhoto

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
             @"observationPhotoId": @"id",
             @"uuid": @"uuid",
             @"position": @"position",
             @"licenseCode": @"photo.license_code",
             @"url": @"photo.url",
             @"attribution": @"attribution",
             };
}

+ (NSValueTransformer *)urlJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
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

- (NSString *)photoKey {
    return nil;
}

- (NSString *)urlStringForSize:(NSString *)size {
    return [self.url.absoluteString stringByReplacingOccurrencesOfString:@"square"
                                                              withString:size];
}

@end
