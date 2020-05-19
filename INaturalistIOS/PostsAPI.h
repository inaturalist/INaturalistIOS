//
//  PostsAPI.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/4/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import "INatAPI.h"

@interface PostsAPI : INatAPI

- (void)userPosts:(INatAPIFetchCompletionCountHandler)done;
- (void)userPostsNewerThanPost:(NSInteger)postId handler:(INatAPIFetchCompletionCountHandler)done;
- (void)userPostsOlderThanPost:(NSInteger)postId handler:(INatAPIFetchCompletionCountHandler)done;
- (void)postsForProjectId:(NSInteger)projectId handler:(INatAPIFetchCompletionCountHandler)done;

@end
