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
        self.dataTransferConsent = model.dataTransferConsent;
        self.piConsent = model.piConsent;
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
    value[@"piConsent"] = @(model.piConsent);
    value[@"dataTransferConsent"] = @(model.dataTransferConsent);
        
    return [NSDictionary dictionaryWithDictionary:value];
}

+ (NSDictionary *)valueForCoreDataModel:(id)cdModel {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    
    if ([cdModel valueForKey:@"recordID"]) {
        value[@"userId"] = [cdModel valueForKey:@"recordID"];
    } else {
        // this is not an uploadable, return nil if we don't have a
        // record id
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
    
    if ([cdModel valueForKey:@"name"]) {
        value[@"name"] = [cdModel valueForKey:@"name"];
    }
    
    if ([cdModel valueForKey:@"userIconURL"]) {
        value[@"userIconString"] = [cdModel valueForKey:@"userIconURL"];
    }
    
    if ([cdModel valueForKey:@"syncedAt"]) {
        value[@"syncedAt"] = [cdModel valueForKey:@"syncedAt"];
    }
    
    // nobody migrating from core data at this point will have consented to
    // pi or data transfer in a way that core data knew about it
    value[@"piConsent"] = @(FALSE);
    value[@"dataTransferConsent"] = @(FALSE);
    
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

- (BOOL)hasJoinedProjectWithId:(NSInteger)projectId {
    for (ExploreProjectRealm *project in self.joinedProjects) {
        if (project.projectId == projectId) { return YES; }
    }
    return NO;
}

@end
