//
//  NSLocale+INaturalist.m
//  iNaturalist
//
//  Created by Alex Shepard on 7/7/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "NSLocale+INaturalist.h"

@implementation NSLocale (INaturalist)

+ (NSString *)inat_serverFormattedLocale {
    // iOS gives us en_US, server expects en-US
    NSString *localeString = [[NSLocale currentLocale] localeIdentifier];
    NSString *serverLocaleIdentifier = [localeString stringByReplacingOccurrencesOfString:@"_" withString:@"-"];
    return serverLocaleIdentifier;
}

@end
