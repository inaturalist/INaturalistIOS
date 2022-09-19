//
//  PostsAPI.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/4/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import "PostsAPI.h"
#import "Analytics.h"
#import "ExplorePost.h"

@implementation PostsAPI

- (void)userPosts:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch user posts from node"];
    NSString *path = @"posts/for_user";
    [self fetch:path classMapping:ExplorePost.class handler:done];
}

- (void)userPostsNewerThanPost:(NSInteger)postId handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch new posts from node"];
    NSString *path = [NSString stringWithFormat:@"posts/for_user?newer_than=%ld", (long)postId];
    [self fetch:path classMapping:ExplorePost.class handler:done];
}

- (void)userPostsOlderThanPost:(NSInteger)postId handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch old posts from node"];
    NSString *path = [NSString stringWithFormat:@"posts/for_user?older_than=%ld", (long)postId];
    [self fetch:path classMapping:ExplorePost.class handler:done];
}

- (void)postsForProjectId:(NSInteger)projectId handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch project posts from node"];
    NSString *path = [NSString stringWithFormat:@"posts?project_id=%ld", (long)projectId];
    [self fetch:path classMapping:ExplorePost.class handler:done];
}

@end
