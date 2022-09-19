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
    static NSISO8601DateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSISO8601DateFormatter alloc] init];
    });

    return [MTLValueTransformer transformerWithBlock:^id(id dateString) {
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
