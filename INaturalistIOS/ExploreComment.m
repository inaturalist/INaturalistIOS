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
	static NSDateFormatter *_dateFormatter = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_dateFormatter = [[NSDateFormatter alloc] init];
		_dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
		_dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
	});

    return [MTLValueTransformer transformerWithBlock:^id(id dateString) {
        return [_dateFormatter dateFromString:dateString];
    }];
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
