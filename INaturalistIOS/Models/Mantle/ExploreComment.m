//
//  ExploreComment.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/10/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreComment.h"
#import "ExploreModeratorAction.h"
#import "ExploreUser.h"

@implementation ExploreComment

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
    	@"commentId": @"id",
    	@"commentText": @"body",
    	@"commenter": @"user",
    	@"commentedDate": @"created_at",
        @"hidden": @"hidden",
        @"moderatorActions": @"moderator_actions",
    };
}

+ (NSValueTransformer *)commenterJSONTransformer {
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ExploreUser.class];
}

+ (NSValueTransformer *)commentedDateJSONTransformer {
    static NSISO8601DateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSISO8601DateFormatter alloc] init];
    });
    
    return [MTLValueTransformer transformerWithBlock:^id(id dateString) {
        return [_dateFormatter dateFromString:dateString];
    }];
}

+ (NSValueTransformer *)moderatorActionsJSONTransformer {
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:ExploreModeratorAction.class];
}


#pragma mark - CommentVisualization

- (NSString *)body {
    return self.commentText;
}

- (NSInteger)userId {
    return self.commenter.userId;
}

- (NSString *)userName {
    return self.commenter.login;
}

- (NSDate *)createdAt {
    return self.commentedDate;
}

- (NSURL *)userIconUrl {
    return self.commenter.userIcon;
}

- (NSDate *)moderationDate {
    ExploreModeratorAction *a = [self.moderatorActions firstObject];
    if (a) {
        return a.date;
    } else {
        return nil;
    }
}

- (NSString *)moderationReason {
    ExploreModeratorAction *a = [self.moderatorActions firstObject];
    if (a) {
        return a.reason;
    } else {
        return nil;
    }
}

- (NSString *)moderatorUsername {
    ExploreModeratorAction *a = [self.moderatorActions firstObject];
    if (a) {
        return a.user.login;
    } else {
        return nil;
    }
}

@end
