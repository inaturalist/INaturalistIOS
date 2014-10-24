//
//  ExploreComment.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/10/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreComment.h"

@implementation ExploreComment

- (NSDate *)date {
    return self.commentedDate;
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



@end
