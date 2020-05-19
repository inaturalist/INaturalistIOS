//
//  ExploreTaxonPhoto.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/17/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import "ExploreTaxonPhoto.h"

@implementation ExploreTaxonPhoto

+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{
             @"taxonPhotoId": @"photo.id",
             @"attribution": @"photo.attribution",
             @"squareUrl": @"photo.square_url",
             @"smallUrl": @"photo.small_url",
             @"mediumUrl": @"photo.medium_url",
             @"largeUrl": @"photo.large_url",
             @"licenseCode": @"photo.license_code",
             };
}

+ (NSValueTransformer *)squareUrlJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)smallUrlJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)mediumUrlJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)largeUrlJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

@end
