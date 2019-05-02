//
//  ExploreFaveRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/12/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import "ExploreFaveRealm.h"

@implementation ExploreFaveRealm

- (instancetype)initWithMantleModel:(ExploreFave *)model {
    if (self = [super init]) {
        self.faveId = model.faveId;
        self.faveDate = model.faveDate;
        if (model.faver) {
            self.faver = [[ExploreUserRealm alloc] initWithMantleModel:model.faver];
        }
    }
    
    return self;
}

+(NSString *)primaryKey {
    return @"faveId";
}

- (NSDate *)createdAt {
    return self.faveDate;
}

- (NSURL *)userIconUrl {
    return self.faver.userIcon;
}

- (NSInteger)userId {
    return self.faver.userId;
}

- (NSString *)userName {
    return self.faver.login;
}

@end
