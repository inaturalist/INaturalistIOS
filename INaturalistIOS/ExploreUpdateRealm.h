//
//  ExploreUpdateRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 10/17/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>
#import "ExploreUpdate.h"
#import "ExploreUserRealm.h"
#import "ExploreCommentRealm.h"
#import "ExploreIdentificationRealm.h"

@interface ExploreUpdateRealm : RLMObject

@property NSDate *createdAt;
@property NSInteger updateId;
@property ExploreIdentificationRealm *identification;
@property ExploreCommentRealm *comment;
@property NSInteger resourceOwnerId;
@property NSInteger resourceId;
@property BOOL viewed;

- (instancetype)initWithMantleModel:(ExploreUpdate *)model;

@end
