//
//  NSLocale+INaturalist.m
//  iNaturalist
//
//  Created by Alex Shepard on 7/7/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "NSLocale+INaturalist.h"

@implementation NSLocale (INaturalist)

- (NSString *)inat_serverFormattedLocale {
    // start with the iOS locale identifier
    NSString *serverLocaleIdentifier = [self localeIdentifier];

    // iOS gives us zh-Hans_cn, server expects zh-CN
    // iOS can also give us zh_SG and zh_MY but we want zh-CN
    if ([serverLocaleIdentifier containsString:@"zh-Hans"]) {
        serverLocaleIdentifier = @"zh-CN";
    } else if ([serverLocaleIdentifier isEqualToString:@"zh_SG"]) {
        serverLocaleIdentifier = @"zh-CN";
    } else if ([serverLocaleIdentifier isEqualToString:@"zh_MY"]) {
        serverLocaleIdentifier = @"zh-MY";
    }

    // iOS gives us zh-Hant_tw, server expects zh-TW
    if ([serverLocaleIdentifier containsString:@"zh-Hant"]) {
        if ([serverLocaleIdentifier containsString:@"TW"]) {
            serverLocaleIdentifier = @"zh-TW";
        } else if ([serverLocaleIdentifier containsString:@"HK"]) {
            serverLocaleIdentifier = @"zh-HK";
        } else if ([serverLocaleIdentifier containsString:@"MO"]) {
            serverLocaleIdentifier = @"zh-MO";
        }
    }

    // iOS gives us en_US, server expects en-US
    serverLocaleIdentifier = [serverLocaleIdentifier stringByReplacingOccurrencesOfString:@"_" withString:@"-"];

    return serverLocaleIdentifier;
}

@end
