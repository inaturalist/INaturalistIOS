//
//  ExploreCommentRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 8/9/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ExploreCommentRealm.h"

@implementation ExploreCommentRealm

- (instancetype)initWithMantleModel:(ExploreComment *)model {
	if (self = [super init]) {
		self.commentId = model.commentId;
		self.commentText = model.commentText;
		self.commentedDate = model.commentedDate;
		self.commenter = [[ExploreUserRealm alloc] initWithMantleModel:model.commenter];
	}
	
	return self;
}

#pragma mark - CommentVisualization & ActivityVisualization

- (NSString *)body {
    return self.commentText;
}

- (NSDate *)createdAt {
    return self.commentedDate;
}

- (NSString *)userName {
    return self.commenter.login;
}

- (NSURL *)userIconUrl {
    return self.commenter.userIcon;
}

- (NSInteger)userId {
    return self.commenter.userId;
}

@end
