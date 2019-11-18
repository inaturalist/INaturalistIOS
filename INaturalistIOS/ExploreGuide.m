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
    return [MTLValueTransformer transformerWithBlock:^id(id dateString) {
        return [[ExploreGuide iNatAPIDateFormatter] dateFromString:dateString];
    }];
}

+ (NSValueTransformer *)updatedAtJSONTransformer {
    return [MTLValueTransformer transformerWithBlock:^id(id dateString) {
        return [[ExploreGuide iNatAPIDateFormatter] dateFromString:dateString];
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
    static NSDateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        // 2013-10-07T16:22:43.123-07:00
        _dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
    });
    
    return _dateFormatter;
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
