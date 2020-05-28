//
//  ExploreUserRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/17/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ExploreUserRealm.h"

@implementation ExploreUserRealm

- (instancetype)initWithMantleModel:(ExploreUser *)model {
    if (self = [super init]) {
        self.userId = model.userId;
        self.login = model.login;
        self.name = model.name;
        self.userIconString = model.userIcon.absoluteString;
        self.email = model.email;
        self.observationsCount = model.observationsCount;
        self.siteId = model.siteId;
        self.syncedAt = [NSDate date];
    }
    return self;
}

+ (NSDictionary *)valueForMantleModel:(ExploreUser *)model {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    
    value[@"userId"] = @(model.userId);
    value[@"login"] = model.login;
    value[@"name"] = model.name;
    value[@"userIconString"] = model.userIcon.absoluteString;
    value[@"email"] = model.email;
    value[@"observationsCount"] = @(model.observationsCount);
    value[@"siteId"] = @(model.siteId);
    value[@"syncedAt"] = [NSDate date];
        
    return [NSDictionary dictionaryWithDictionary:value];
}

+ (NSDictionary *)valueForCoreDataModel:(id)cdModel {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    
    if ([cdModel valueForKey:@"recordID"]) {
        value[@"userId"] = [cdModel valueForKey:@"recordID"];
    } else {
        return nil;
    }
    
    if ([cdModel valueForKey:@"siteId"]) {
        value[@"siteId"] = [cdModel valueForKey:@"siteId"];
    } else {
        // default site is iNat
        value[@"siteId"] = @(1);
    }

    if ([cdModel valueForKey:@"login"]) {
        value[@"login"] = [cdModel valueForKey:@"login"];
    } else {
        return nil;
    }
    
    if ([cdModel valueForKey:@"observationsCount"]) {
        value[@"observationsCount"] = [cdModel valueForKey:@"observationsCount"];
    } else {
        value[@"observationsCount"] = @(0);
    }
    
    // these can be nil
    value[@"name"] = [cdModel valueForKey:@"name"];
    value[@"userIconString"] = [cdModel valueForKey:@"userIconURL"];
    value[@"syncedAt"] = [cdModel valueForKey:@"syncedAt"];
        
    return [NSDictionary dictionaryWithDictionary:value];
}


+ (NSString *)primaryKey {
    return @"userId";
}

- (NSURL *)userIcon {
    return [NSURL URLWithString:self.userIconString];
}

- (NSURL *)userIconMedium {
    NSString *mediumUrlString = [self.userIconString stringByReplacingOccurrencesOfString:@"thumb"
                                                                               withString:@"medium"];
    return [NSURL URLWithString:mediumUrlString];
}

@end
