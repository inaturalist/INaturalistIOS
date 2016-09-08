//
//  ExploreUserRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 8/9/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>
#import "ExploreUser.h"

@interface ExploreUserRealm : RLMObject

@property NSInteger userId;
@property NSString *login;
@property NSString *name;
@property NSString *userIconUrlString;
@property NSInteger observationsCount;
@property NSInteger identificationsCount;

@property (readonly) NSURL *userIcon;

- (instancetype)initWithMantleModel:(ExploreUser *)model;

@end
