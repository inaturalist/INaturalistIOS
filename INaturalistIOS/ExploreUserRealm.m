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
