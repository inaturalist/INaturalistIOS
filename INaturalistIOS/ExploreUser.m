//
//  ExploreUser.m
//  iNaturalist
//
//  Created by Alex Shepard on 6/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ExploreUser.h"

@implementation ExploreUser

+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{
             @"userId": @"id",
             @"login": @"login",
             @"name": @"name",
             @"userIcon": @"icon_url",
             };
}

+ (NSValueTransformer *)userIconJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

@end
