//
//  ExploreUserRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 10/17/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>
#import "ExploreUser.h"

@interface ExploreUserRealm : RLMObject

@property NSInteger userId;
@property NSString *login;
@property NSString *name;
@property NSString *userIconString;

@property (readonly) NSURL *userIcon;

- (instancetype)initWithMantleModel:(ExploreUser *)model;

@end
