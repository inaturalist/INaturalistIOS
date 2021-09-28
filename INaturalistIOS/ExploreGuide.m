//
//  ExploreGuide.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/13/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import "ExploreGuide.h"
#import "ExploreTaxon.h"

@implementation ExploreGuide

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"guideId": @"id",
        @"title": @"title",
        @"desc": @"description",
        @"createdAt": @"created_at",
        @"updatedAt": @"updated_at",
        @"iconURL": @"icon_url",
        @"taxonId": @"taxon_id",
        @"latitude": @"latitude",
        @"longitude": @"longitude",
        @"userLogin": @"user_login",
    };
}

+ (NSValueTransformer *)taxonJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ExploreTaxon.class];
}

+ (NSValueTransformer *)iconURLJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
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

+ (NSValueTransformer *)updatedAtJSONTransformer {
    static NSISO8601DateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSISO8601DateFormatter alloc] init];
    });

    return [MTLValueTransformer transformerWithBlock:^id(id dateString) {
        return [_dateFormatter dateFromString:dateString];
    }];
}

- (void)setNilValueForKey:(NSString *)key {
    if ([key isEqualToString:@"latitude"]) {
        self.latitude = kCLLocationCoordinate2DInvalid.latitude;
    } else if ([key isEqualToString:@"longitude"]) {
        self.longitude = kCLLocationCoordinate2DInvalid.longitude;
    } else if ([key isEqualToString: @"taxonId"]) {
        self.taxonId = 0;
    } else {
        [super setNilValueForKey:key];
    }
}

/*
 helper for the date json transformers
 */
+ (NSDateFormatter *)iNatAPIDateFormatter {
    static NSISO8601DateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSISO8601DateFormatter alloc] init];
    });

    return [MTLValueTransformer transformerWithBlock:^id(id dateString) {
        return [_dateFormatter dateFromString:dateString];
    }];
}

- (NSDictionary *)serializableRepresentation {
    return @{
        @"guideId": @(self.guideId),
        @"title": self.title,
        @"desc": self.desc,
        @"createdAt": self.createdAt,
        @"updatedAt": self.updatedAt,
        @"iconUrlString": [self.iconURL absoluteString],
        @"taxonId": @(self.taxonId),
        @"latitude": @(self.latitude),
        @"longitude": @(self.longitude),
        @"userLogin": self.userLogin,
    };
}

@end
