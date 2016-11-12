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

// inat-wide sense of whether the update has been seen
// locally, this means whether it's been seen in the updates list view
// tab and app badging are computed from this
@property BOOL viewed;

// local sense of whether the update has been seen
// locally, this means whether it's been seen in the updates detail view
// there's a special visual treatment for this state
// this value may get overwritten by the inat-wide sense of
// viewed on RLMRealm -addOrUpdate
@property BOOL viewedLocally;

- (instancetype)initWithMantleModel:(ExploreUpdate *)model;

@end
