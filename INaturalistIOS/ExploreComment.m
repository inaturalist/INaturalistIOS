//
//  ExploreComment.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/10/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreComment.h"
#import "ExploreUser.h"

@implementation ExploreComment

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
    	@"commentId": @"id",
    	@"commentText": @"body",
    	@"commenter": @"user",
    	@"commentedDate": @"created_at",
    };
}

+ (NSValueTransformer *)commenterJSONTransformer {
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ExploreUser.class];
}

+ (NSValueTransformer *)commentedDateJSONTransformer {
    // fractional seconds in the automatic 8601 date parser are ios 11 and over
    if (@available(iOS 11.0, *)) {
        static NSISO8601DateFormatter *_dateFormatter = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _dateFormatter = [[NSISO8601DateFormatter alloc] init];
            _dateFormatter.formatOptions = NSISO8601DateFormatWithInternetDateTime|NSISO8601DateFormatWithFractionalSeconds;
        });
        
        return [MTLValueTransformer transformerWithBlock:^id(id dateString) {
            return [_dateFormatter dateFromString:dateString];
        }];
    } else {
        static NSDateFormatter *_dateFormatter = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _dateFormatter = [[NSDateFormatter alloc] init];
            _dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ";
        });
        
        return [MTLValueTransformer transformerWithBlock:^id(id dateString) {
            return [_dateFormatter dateFromString:dateString];
        }];
    }
    

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

@end
