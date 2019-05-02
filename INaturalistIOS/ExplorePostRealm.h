//
//  ExplorePostRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 10/29/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import "RLMObject.h"
#import "ExplorePost.h"

@interface ExplorePostRealm : RLMObject

// properties related to the parent
@property NSString *parentType;
@property NSString *parentIconUrlString;
@property NSString *parentProjectTitle;
@property NSInteger parentId;
@property NSString *parentSiteShortName;

// properties for the post
@property NSInteger postId;
@property NSDate *publishedAt;
@property NSString *title;
@property NSString *body;
@property NSString *excerpt;
@property NSString *coverImageUrlString;

// properties for the author
@property NSString *authorLogin;
@property NSString *authorIconUrlString;

@property (readonly) NSURL *coverImageUrl;
@property (readonly) NSURL *parentIconUrl;
@property (readonly) NSURL *urlForNewsItem;
@property (readonly) NSURL *authorIconUrl;

- (instancetype)initWithMantleModel:(ExplorePost *)model;

@end


RLM_ARRAY_TYPE(ExplorePostRealm)
