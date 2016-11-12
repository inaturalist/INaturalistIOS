//
//  ExploreUpdateRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/17/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ExploreUpdateRealm.h"

@implementation ExploreUpdateRealm

- (instancetype)initWithMantleModel:(ExploreUpdate *)model {
    if (self = [super init]) {
        self.createdAt = model.createdAt;
        self.updateId = model.updateId;
        if (model.identification) {
            self.identification = [[ExploreIdentificationRealm alloc] initWithMantleModel:model.identification];
        } else if (model.comment) {
            self.comment = [[ExploreCommentRealm alloc] initWithMantleModel:model.comment];
        }
        self.resourceOwnerId = model.resourceOwnerId;
        self.resourceId = model.resourceId;
        self.viewed = model.viewed;
        self.viewedLocally = model.viewed;
    }
    return self;
}

+ (NSString *)primaryKey {
    return @"updateId";
}

@end
