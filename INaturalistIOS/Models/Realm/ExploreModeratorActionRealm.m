//
//  ExploreModeratorActionRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 12/13/23.
//  Copyright © 2023 iNaturalist. All rights reserved.
//

#import "ExploreModeratorActionRealm.h"
#import "ExploreUser.h"

@implementation ExploreModeratorActionRealm
//@property NSInteger actionId;
//@property NSDate *date;
//@property NSString *moderator;
//@property NSString *action;
//@property NSString *reason;
//

- (instancetype)initWithMantleModel:(ExploreModeratorAction *)model {
    if (self = [super init]) {
        self.actionId = model.actionId;
        self.date = model.date;
        self.moderator = model.user.login;
        self.action = model.action;
        self.reason = model.reason;
    }
    return self;
}

+ (NSDictionary *)valueForMantleModel:(ExploreModeratorAction *)model {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    
    value[@"actionId"] = @(model.actionId);
    value[@"date"] = model.date;
    value[@"moderator"] = model.user.login;
    value[@"action"] = model.action;
    value[@"reason"] = model.reason;

    return [NSDictionary dictionaryWithDictionary:value];
}


@end
