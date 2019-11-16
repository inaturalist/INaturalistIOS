//
//  ExploreGuideRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/15/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import "ExploreGuideRealm.h"

@implementation ExploreGuideRealm

+ (NSDictionary *)valueForMantleModel:(ExploreGuide *)model {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    value[@"guideId"] = @(model.guideId);
    if (model.title) { value[@"title"] = model.title; }
    if (model.desc) { value[@"desc"] = model.desc; }
    if (model.createdAt) { value[@"createdAt"] = model.createdAt; }
    if (model.updatedAt) { value[@"updatedAt"] = model.updatedAt; }
    if (model.iconURL) { value[@"iconUrlString"] = model.iconURL.absoluteString; }
    value[@"taxonId"] = @(model.taxonId);
    value[@"latitude"] = @(model.latitude);
    value[@"longitude"] = @(model.longitude);
    if (model.userLogin) { value[@"userLogin"] = model.userLogin; }
    
    return [NSDictionary dictionaryWithDictionary:value];
}

+ (NSDictionary *)valueForCoreDataModel:(Guide *)model {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    
    if (model.recordID) { value[@"guideId"] = model.recordID; }
    if (model.title) { value[@"title"] = model.title; }
    if (model.desc) { value[@"desc"] = model.desc; }
    if (model.createdAt) { value[@"createdAt"] = model.createdAt; }
    if (model.updatedAt) { value[@"updatedAt"] = model.updatedAt; }
    if (model.iconURL) { value[@"iconUrlString"] = model.iconURL; }
    if (model.taxonID) { value[@"taxonId"] = model.taxonID; }
    if (model.latitude) { value[@"latitude"] = model.latitude; }
    if (model.longitude) { value[@"longitude"] = model.longitude; }
    if (model.ngzDownloadedAt) { value[@"ngsDownloadedAt"] = model.ngzDownloadedAt; }
    
    return [NSDictionary dictionaryWithDictionary:value];
}

- (instancetype)initWithMantleModel:(ExploreGuide *)model {
    if (self = [super init]) {
        self.guideId = model.guideId;
        self.title = model.title;
        self.desc = model.desc;
        self.createdAt = model.createdAt;
        self.updatedAt = model.updatedAt;
        self.iconUrlString = model.iconURL.absoluteString;
        self.taxonId = model.taxonId;
        self.latitude = model.latitude;
        self.longitude = model.longitude;
        self.userLogin = model.userLogin;
    }
    return self;
}

+ (NSString *)primaryKey {
    return @"guideId";
}

- (NSURL *)iconURL {
    return [NSURL URLWithString:self.iconUrlString];
}

@end
