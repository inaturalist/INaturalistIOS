//
//  CommentsAPI.h
//  iNaturalist
//
//  Created by Alex Shepard on 12/5/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import "INatAPI.h"

@interface CommentsAPI : INatAPI

- (void)addComment:(NSString *)body observationId:(NSInteger)obsId handler:(INatAPIFetchCompletionCountHandler)done;
- (void)deleteComment:(NSInteger)commentId handler:(INatAPIFetchCompletionCountHandler)done;
- (void)updateComment:(NSInteger)commentId newBody:(NSString *)body handler:(INatAPIFetchCompletionCountHandler)done;

@end
