//
//  ExploreProject.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/2/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreProject.h"
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>
#import "ExploreProjectObsField.h"

@implementation ExploreProject

+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{
             @"title": @"title",
             @"projectId": @"id",
             @"locationId": @"place_id",
             @"latitude": @"latitude",
             @"longitude": @"longitude",
             @"iconUrl": @"icon",
             @"type": @"project_type",
             @"bannerColorString": @"banner_color",
             @"bannerImageUrl": @"header_image_url",
             @"inatDescription": @"description",
             @"projectObsFields": @"project_observation_fields",
             };
}

+ (NSValueTransformer *)iconUrlJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)bannerImageUrlJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)projectObsFieldsJSONTransformer {
    return [MTLValueTransformer mtl_JSONArrayTransformerWithModelClass:ExploreProjectObsField.class];
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
        self.latitude = kCLLocationCoordinate2DInvalid.latitude;
    } else if ([key isEqualToString:@"longitude"]) {
        self.longitude = kCLLocationCoordinate2DInvalid.longitude;
    } else if ([key isEqualToString:@"type"]) {
        self.type = ExploreProjectTypeOldStyle;
    } else {
        [super setNilValueForKey:key];
    }
}

- (BOOL)joined {
    return NO;
}

- (UIColor *)bannerColor {
    if (self.bannerColorString) {
        return [UIColor colorWithHexString:self.bannerColorString];
    } else {
        return [UIColor clearColor];
    }
}

- (NSArray *)sortedProjectObsFields {
    NSSortDescriptor *position = [NSSortDescriptor sortDescriptorWithKey:@"position"
                                                               ascending:YES];
    return [self.projectObsFields sortedArrayUsingDescriptors:@[ position ]];
}

@end
