//
//  ExplorePost.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/4/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import <Mantle/Mantle.h>

typedef NS_ENUM(NSInteger, PostParentType) {
    PostParentTypeSite,
    PostParentTypeProject
};


@interface ExplorePost : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, assign) NSInteger postId;
@property (nonatomic, copy) NSDate *postPublishedAt;
@property (nonatomic, copy) NSString *postTitle;
@property (nonatomic, copy) NSString *postBody;

// parent properties
@property (nonatomic, assign) NSInteger parentId;
@property (nonatomic, copy) NSString *parentSiteName;
@property (nonatomic, copy) NSString *parentProjectTitle;
@property (nonatomic, copy) NSString *parentSiteShortName;
@property (nonatomic, copy) NSURL *parentIconUrl;
@property (nonatomic, assign) PostParentType parentType;

// author properties
@property (nonatomic, copy) NSString *authorLogin;
@property (nonatomic, copy) NSString *authorIconUrl;

// computed properties
@property (nonatomic, copy) NSString *postPlainTextExcerpt;
@property (nonatomic, copy) NSURL *postCoverImageUrl;
@property (readonly) NSString *parentTitleText;
@property (readonly) NSURL *urlForNewsItem;

- (void)computeProperties;

@end
