//
//  ExploreUpdate.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/17/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ExploreUpdate.h"

@implementation ExploreUpdate

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"createdAt": @"created_at",
             @"updateId": @"id",
             @"identification": @"identification",
             @"comment": @"comment",
             @"resourceOwnerId": @"resource_owner_id",
             @"resourceId": @"resource_id",
             @"viewed": @"viewed",
             };
}


+ (NSValueTransformer *)createdAtJSONTransformer {
    // 2016-10-21T11:16:15.536-07:00
    
    return [MTLValueTransformer transformerWithBlock:^id(id dateString) {
        
        static NSDateFormatter *_dateFormatter = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _dateFormatter = [[NSDateFormatter alloc] init];
            _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
            _dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
        });

        return [_dateFormatter dateFromString:dateString];
    }];
}

+ (NSValueTransformer *)identificationJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ExploreIdentification.class];
}

+ (NSValueTransformer *)commentJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ExploreComment.class];
}


@end
