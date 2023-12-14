//
//  ExploreModeratorAction.m
//  iNaturalist
//
//  Created by Alex Shepard on 12/13/23.
//  Copyright © 2023 iNaturalist. All rights reserved.
//

#import "ExploreModeratorAction.h"
#import "ExploreUser.h"

@implementation ExploreModeratorAction

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"actionId": @"id",
        @"date": @"created_at",
        @"user": @"user",
        @"action": @"action",
        @"reason": @"reason",
    };
}

+ (NSValueTransformer *)userJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ExploreUser.class];
}

+ (NSValueTransformer *)dateJSONTransformer {
    static NSISO8601DateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSISO8601DateFormatter alloc] init];
        _dateFormatter.formatOptions = NSISO8601DateFormatWithFractionalSeconds|NSISO8601DateFormatWithInternetDateTime;
    });

    return [MTLValueTransformer transformerWithBlock:^id(id dateString) {
        return [_dateFormatter dateFromString:dateString];
    }];
}

@end
