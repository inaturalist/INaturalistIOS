//
//  ExploreProject.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/2/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreProject.h"

@implementation ExploreProjectSiteFeatures
+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{
             @"siteId": @"site_id",
             @"featuredAt": @"featured_at",
             };
}

+ (NSValueTransformer *)featuredAtJSONTransformer {
    static NSDateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        _dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    });
    
    return [MTLValueTransformer transformerWithBlock:^id(id dateString) {
        return [_dateFormatter dateFromString:dateString];
    }];
}

@end

@implementation ExploreProject

+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{
             @"title": @"title",
             @"inatDescription": @"description",
             @"projectId": @"id",
             @"locationId": @"place_id",
             @"latitude": @"latitude",
             @"longitude": @"longitude",
             @"iconUrl": @"icon",
             @"siteFeatures": @"site_features",
             @"terms": @"terms",
             @"type": @"project_type",
             @"fields": @"project_observation_fields"
             };
}

+ (NSValueTransformer *)iconUrlJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)typeJSONTransformer {
    NSDictionary *typeMappings = @{
                                   @"collection": @(ExploreProjectTypeCollection),
                                   @"umbrella": @(ExploreProjectTypeUmbrella),
                                   @"": @(ExploreProjectTypeOldStyle),
                                   };
    
    return [NSValueTransformer mtl_valueMappingTransformerWithDictionary:typeMappings];
}

- (void)setNilValueForKey:(NSString *)key {
    if ([key isEqualToString:@"locationId"]) {
        self.locationId = 0;
    } else if ([key isEqualToString:@"latitude"]) {
        self.latitude = 0.0;
    } else if ([key isEqualToString:@"longitude"]) {
        self.longitude = 0.0;
    } else if ([key isEqualToString:@"type"]) {
        self.type = ExploreProjectTypeOldStyle;
    } else {
        [super setNilValueForKey:key];
    }
}

+ (NSValueTransformer *)siteFeaturesJSONTransformer {
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:ExploreProjectSiteFeatures.class];
}

+ (NSValueTransformer *)fieldsJSONTransformer {
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:ExploreProjectObservationField.class];
}


- (BOOL)joined {
    return NO;
}

- (NSArray<ExploreProjectObservationField *> *)requiredFields {
    NSPredicate *required = [NSPredicate predicateWithFormat:@"required == TRUE"];
    return [[self fields] filteredArrayUsingPredicate:required];
}

@end
