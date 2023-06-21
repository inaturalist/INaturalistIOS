//
//  ExploreAnnouncement.m
//  iNaturalist
//
//  Created by Alex Shepard on 6/13/23.
//  Copyright © 2023 iNaturalist. All rights reserved.
//

#import "ExploreAnnouncement.h"

@implementation ExploreAnnouncement

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"announcementId": @"id",
        @"body": @"body",
        @"startDate": @"start",
        @"dismissible": @"dismissible",
        @"placement": @"placment",
    };
}

+ (NSValueTransformer *)startDateJSONTransformer {
    static NSISO8601DateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSISO8601DateFormatter alloc] init];
    });

    return [MTLValueTransformer transformerWithBlock:^id(id dateString) {
        return [_dateFormatter dateFromString:dateString];
    }];
}


@end
