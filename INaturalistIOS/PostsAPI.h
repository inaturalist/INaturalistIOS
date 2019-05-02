//
//  PostsAPI.h
//  iNaturalist
//
//  Created by Alex Shepard on 10/29/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import "INatAPI.h"

@interface PostsAPI : INatAPI

- (void)newSitePostsHandler:(INatAPIFetchCompletionCountHandler)done;
- (void)sitePostsOlderThan:(NSInteger)postId handler:(INatAPIFetchCompletionCountHandler)done;

- (void)newPostsForProjectId:(NSInteger)projectId handler:(INatAPIFetchCompletionCountHandler)done;
- (void)postsForProjectId:(NSInteger)projectId olderThan:(NSInteger)olderPostId handler:(INatAPIFetchCompletionCountHandler)done;

@end
