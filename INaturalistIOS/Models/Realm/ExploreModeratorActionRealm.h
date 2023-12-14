//
//  ExploreModeratorActionRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 12/13/23.
//  Copyright © 2023 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>

#import "ExploreModeratorAction.h"

@interface ExploreModeratorActionRealm : RLMObject

@property NSInteger actionId;
@property NSDate *date;
@property NSString *moderator;
@property NSString *action;
@property NSString *reason;

- (instancetype)initWithMantleModel:(ExploreModeratorAction *)model;
+ (NSDictionary *)valueForMantleModel:(ExploreModeratorAction *)model;

@end

RLM_COLLECTION_TYPE(ExploreModeratorActionRealm)


