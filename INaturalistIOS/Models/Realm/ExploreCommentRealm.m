//
//  ExploreCommentRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/17/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ExploreCommentRealm.h"
#import "ExploreObservationRealm.h"

@implementation ExploreCommentRealm

- (instancetype)initWithMantleModel:(ExploreComment *)model {
    if (self = [super init]) {
        self.commentId = model.commentId;
        self.commentText = model.commentText;
        self.commentedDate = model.commentedDate;
        self.hidden = model.hidden;
        if (model.commenter) {
            self.commenter = [[ExploreUserRealm alloc] initWithMantleModel:model.commenter];
        }
    }
    return self;
}

+ (NSDictionary *)linkingObjectsProperties {
    return @{
        @"observations": [RLMPropertyDescriptor descriptorWithClass:ExploreObservationRealm.class propertyName:@"comments"],
    };
}

+ (NSDictionary *)valueForMantleModel:(ExploreComment *)model {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    
    value[@"commentId"] = @(model.commentId);
    value[@"commentText"] = model.commentText;
    value[@"commentedDate"] = model.commentedDate;
    value[@"hidden"] = @(model.hidden);
    if (model.commenter) {
        value[@"commenter"] = [ExploreUserRealm valueForMantleModel:model.commenter];
    }
    
    return [NSDictionary dictionaryWithDictionary:value];
}

+ (NSDictionary *)valueForCoreDataModel:(id)cdModel {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    
    if ([cdModel valueForKey:@"recordID"]) {
        value[@"commentId"] = [cdModel valueForKey:@"recordID"];
    } else {
        // this is not an uploadable, return nil if we don't have a
        // record id
        return nil;
    }
    
    if ([cdModel valueForKey:@"createdAt"]) {
        value[@"commentDate"] = [cdModel valueForKey:@"createdAt"];
    }
    
    if ([cdModel valueForKey:@"body"]) {
        value[@"commentText"] = [cdModel valueForKey:@"body"];
    }

    if ([cdModel valueForKey:@"user"]) {
        value[@"user"] = [ExploreUserRealm valueForCoreDataModel:[cdModel valueForKey:@"user"]];
    }

    value[@"hidden"] = @(NO);

    return [NSDictionary dictionaryWithDictionary:value];
}

+ (NSString *)primaryKey {
    return @"commentId";
}

#pragma mark - CommentVisualization

- (NSString *)body {
    return self.commentText;
}

-(NSString *)userName {
    return self.commenter.login;
}

- (NSInteger)userId {
    return self.commenter.userId;
}

- (NSURL *)userIconUrl {
    return self.commenter.userIcon;
}

- (NSDate *)createdAt {
    return self.commentedDate;
}

@end
