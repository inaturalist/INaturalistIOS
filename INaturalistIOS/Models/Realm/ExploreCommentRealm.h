//
//  ExploreCommentRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 10/17/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>

#import "CommentVisualization.h"
#import "ExploreModeratorActionRealm.h"
#import "ExploreComment.h"
#import "ExploreUserRealm.h"

@interface ExploreCommentRealm : RLMObject <CommentVisualization>

@property NSInteger commentId;
@property NSString *commentText;
@property ExploreUserRealm *commenter;
@property NSDate *commentedDate;
@property BOOL hidden;

@property (readonly) RLMLinkingObjects *observations;

@property RLMArray<ExploreModeratorActionRealm *><ExploreModeratorActionRealm> *moderatorActions;

- (instancetype)initWithMantleModel:(ExploreComment *)model;
+ (NSDictionary *)valueForMantleModel:(ExploreComment *)model;
+ (NSDictionary *)valueForCoreDataModel:(id)cdModel;

@end

RLM_COLLECTION_TYPE(ExploreCommentRealm)
