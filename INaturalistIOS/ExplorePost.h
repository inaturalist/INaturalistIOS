//
//  ExplorePost.h
//  iNaturalist
//
//  Created by Alex Shepard on 10/29/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import "MTLModel.h"
#import "ExploreUser.h"



@interface ExplorePost : MTLModel <MTLJSONSerializing>

// properties related to the parent
@property (nonatomic, copy) NSString *parentType;
@property (nonatomic, copy) NSURL *parentIconUrl;
@property (nonatomic, copy) NSString *parentProjectTitle;
@property (assign) NSInteger parentId;
@property (nonatomic, copy) NSString *parentSiteShortName;

// properties for the post
@property (assign) NSInteger postId;
@property (nonatomic, copy) NSDate *publishedAt;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *body;
@property (nonatomic, copy) NSString *excerpt;
@property (nonatomic, copy) NSURL *coverImageUrl;

// properties for the author
@property (nonatomic, copy) NSString *authorLogin;
@property (nonatomic, copy) NSURL *authorIconUrl;

@property (readonly) NSURL *urlForNewsItem;

@end
