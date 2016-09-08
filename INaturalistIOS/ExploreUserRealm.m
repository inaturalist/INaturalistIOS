//
//  ExploreUserRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 8/9/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ExploreUserRealm.h"

@implementation ExploreUserRealm

- (instancetype)initWithMantleModel:(ExploreUser *)model {
    if (self = [super init]) {
        self.userId = model.userId;
        self.login = model.login;
        self.name = model.name;
        self.userIconUrlString = [model.userIcon absoluteString];
        self.observationsCount = model.observationsCount;
        self.identificationsCount = model.identificationsCount;
    }
    
    return self;
}

- (NSURL *)userIcon {
    return [NSURL URLWithString:self.userIconUrlString];
}

+ (NSString *)primaryKey {
    return @"userId";
}


@end
