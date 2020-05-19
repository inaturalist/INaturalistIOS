//
//  ExploreFaveRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/3/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import "ExploreFaveRealm.h"

@implementation ExploreFaveRealm

+ (NSDictionary *)valueForMantleModel:(ExploreFave *)model {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    
    value[@"faveDate"] = model.faveDate;
    value[@"faveId"] = @(model.faveId);
    
    if (model.faver) {
        value[@"faver"] = [ExploreUserRealm valueForMantleModel:model.faver];
    }
        
    return [NSDictionary dictionaryWithDictionary:value];
}

- (NSString *)userName {
    return self.faver.login;
}

- (NSInteger)userId {
    return self.faver.userId;
}

- (NSURL *)userIconUrl {
    return self.faver.userIcon;
}

- (NSDate *)createdAt {
    return self.faveDate;
}


@end
