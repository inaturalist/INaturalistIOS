//
//  ExploreUserRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 10/17/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>

#import "ExploreUser.h"
#import "UserVisualization.h"

@interface ExploreUserRealm : RLMObject <UserVisualization>

@property NSInteger userId;
@property NSString *login;
@property NSString *name;
@property NSString *userIconString;
@property NSString *email;
@property NSInteger observationsCount;
@property NSInteger siteId;

@property (readonly) NSURL *userIcon;
@property (readonly) NSURL *userIconMedium;

- (instancetype)initWithMantleModel:(ExploreUser *)model;

@end
