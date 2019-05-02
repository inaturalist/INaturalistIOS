//
//  PostsAPI.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/29/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import "PostsAPI.h"
#import "Analytics.h"
#import "ExplorePost.h"

@implementation PostsAPI

- (void)newSitePostsHandler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch new site posts from node"];
    NSString *path = @"posts?per_page=100";
    [self fetch:path classMapping:[ExplorePost class] handler:done];
}

- (void)sitePostsOlderThan:(NSInteger)olderPostId handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch older site posts from node"];
    NSString *path = [NSString stringWithFormat:@"posts?per_page=100&older_than=%ld",
                      (long)olderPostId];
    [self fetch:path classMapping:[ExplorePost class] handler:done];
}

- (void)newPostsForProjectId:(NSInteger)projectId handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch new project posts from node"];
    NSString *path = [NSString stringWithFormat:@"posts?project_id=%ld&per_page=100",
                      (long)projectId];
    [self fetch:path classMapping:[ExplorePost class] handler:done];
}

- (void)postsForProjectId:(NSInteger)projectId olderThan:(NSInteger)olderPostId handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch older project posts from node"];
    NSString *path = [NSString stringWithFormat:@"posts?project_id=%ld&older_than=%ld&per_page=100",
                      (long)projectId, (long)olderPostId];
    [self fetch:path classMapping:[ExplorePost class] handler:done];
}

@end
