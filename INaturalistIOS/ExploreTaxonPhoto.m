//
//  ExploreTaxonPhoto.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/17/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import "ExploreTaxonPhoto.h"


/*
 @property (nonatomic, assign) NSInteger taxonPhotoId;
 @property (nonatomic, copy) NSString *attribution;
 @property (nonatomic, copy) NSURL *nativePageUrl;
 @property (nonatomic, copy) NSURL *squareUrl;
 @property (nonatomic, copy) NSURL *smallUrl;
 @property (nonatomic, copy) NSURL *mediumUrl;
 @property (nonatomic, copy) NSURL *largeUrl;
*/

@implementation ExploreTaxonPhoto

+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{
             @"taxonPhotoId": @"photo.id",
             @"attribution": @"photo.attribution",
             @"nativePageUrl": @"photo.native_page_url",
             @"squareUrl": @"photo.square_url",
             @"smallUrl": @"photo.small_url",
             @"mediumUrl": @"photo.medium_url",
             @"largeUrl": @"photo.large_url",
             };
}

+ (NSValueTransformer *)nativePageUrlJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
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
