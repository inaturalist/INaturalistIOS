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
    
    // have to supply all values here, no nil options allowed
    if (model.recordID) {
        value[@"guideId"] = model.recordID;
    } else {
        // can't have a guide with no guide id
        return nil;
    }
    
    // these values can be nil in the model
    value[@"title"] = model.title;
    value[@"desc"] = model.desc;
    value[@"createdAt"] = model.createdAt;
    value[@"updatedAt"] = model.updatedAt;
    value[@"iconUrlString"] = model.iconURL;
    value[@"ngzDownloadedAt"] = model.ngzDownloadedAt ?: nil;
    
    // primitive values can't be nil
    value[@"taxonId"] = model.taxonID ?: @(0);
    value[@"latitude"] = model.latitude ?: @(kCLLocationCoordinate2DInvalid.latitude);
    value[@"longitude"] = model.longitude ?: @(kCLLocationCoordinate2DInvalid.longitude);
        
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
