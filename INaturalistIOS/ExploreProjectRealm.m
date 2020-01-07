//
//  ExploreProjectRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/6/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "ExploreProjectRealm.h"

@implementation ExploreProjectRealm

+ (NSDictionary *)valueForMantleModel:(ExploreProject *)model {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    value[@"projectId"] = @(model.projectId);
    
    if (model.title) { value[@"title"] = model.title; }
    if (model.iconUrl) { value[@"iconUrlString"] = model.iconUrl.absoluteString; }
    if (model.bannerImageUrl) { value[@"bannerImageUrlString"] = model.bannerImageUrl.absoluteString; }
    if (model.bannerColorString) { value[@"bannerColorString"] = model.bannerColorString; }

    value[@"latitude"] = @(model.latitude);
    value[@"longitude"] = @(model.longitude);
    value[@"type"] = @(model.type);
    value[@"locationId"] = @(model.locationId);
    value[@"joined"] = @(NO);
    
    return [NSDictionary dictionaryWithDictionary:value];
}

+ (NSDictionary *)valueForCoreDataModel:(Project *)model {
    /*
     TBD
     */
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    return value;
}

- (instancetype)initWithMantleModel:(ExploreProject *)model {
    if (self = [super init]) {
        self.projectId = model.projectId;
        self.title = model.title;
        self.locationId = model.locationId;
        self.latitude = model.latitude;
        self.longitude = model.longitude;
        self.iconUrlString = model.iconUrl.absoluteString;
        self.bannerImageUrlString = model.bannerImageUrl.absoluteString;
        self.type = model.type;
        self.joined = NO;
    }
    return self;
}

+ (NSString *)primaryKey {
    return @"projectId";
}

- (NSURL *)iconUrl {
    return [NSURL URLWithString:self.iconUrlString];
}

- (NSURL *)bannerImageUrl {
    return [NSURL URLWithString:self.bannerImageUrlString];
}

- (UIColor *)bannerColor {
    if (self.bannerColorString) {
        return [UIColor colorWithHexString:self.bannerColorString];
    } else {
        return [UIColor clearColor];
    }
}

+ (RLMResults *)joinedProjects {
    RLMResults *joinedProjects = [[self class] objectsWhere:@"joined = YES"];
    return [joinedProjects sortedResultsUsingDescriptors:[ExploreProjectRealm titleSortDescriptors]];
}

+ (NSArray *)titleSortDescriptors {
    return @[
        [RLMSortDescriptor sortDescriptorWithKeyPath:@"title" ascending:YES],
    ];
}


@end
