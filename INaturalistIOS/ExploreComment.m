//
//  ExploreComment.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/10/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreComment.h"

@implementation ExploreComment

#pragma mark - CommentVisualization

- (NSString *)body {
    return self.commentText;
}

- (NSInteger)userId {
    return self.commenterId;
}

- (NSString *)userName {
    return self.commenterName;
}

- (NSDate *)createdAt {
    return self.commentedDate;
}

- (NSURL *)userIconUrl {
    return [NSURL URLWithString:self.commenterIconUrl];
}

- (BOOL)validateCommentId:(id *)ioValue error:(NSError **)outError {
    // Reject a comment ID of zero. By returning NO, we refused the assignment and the value will not be set
    if ([(NSNumber*)*ioValue intValue] == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateCommenterId:(id *)ioValue error:(NSError **)outError {
    // Reject a commenter ID of zero. By returning NO, we refused the assignment and the value will not be set
    if ([(NSNumber*)*ioValue intValue] == 0) {
        return NO;
    }
    
    return YES;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Explore Comment by %@ at %@",
            self.userName, self.createdAt.description];
}

@end
