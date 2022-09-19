//
//  CommentsAPI.m
//  iNaturalist
//
//  Created by Alex Shepard on 12/5/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import "CommentsAPI.h"
#import "Analytics.h"

@implementation CommentsAPI

- (void)addComment:(NSString *)body observationId:(NSInteger)obsId handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - post comment via node"];
    NSString *path = @"comments";
    NSDictionary *comment = @{
                              @"parent_type": @"Observation",
                              @"parent_id": @(obsId),
                              @"body": body,
                              };
    NSDictionary *params = @{ @"comment": comment };
    [self post:path params:params classMapping:nil handler:done];
}

- (void)deleteComment:(NSInteger)commentId handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - delete comment via node"];
    NSString *path = [NSString stringWithFormat:@"comments/%ld", (long)commentId];
    [self delete:path handler:done];
}

- (void)updateComment:(NSInteger)commentId newBody:(NSString *)body handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - update/put comment via node"];
    NSString *path = [NSString stringWithFormat:@"comments/%ld", (long)commentId];

    NSDictionary *params = @{ @"comment": @{ @"body": body, } };
    [self put:path params:params classMapping:nil handler:done];
}

@end
