//
//  ExploreFave.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/8/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ExploreFave.h"
#import "ExploreUser.h"

@implementation ExploreFave

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{
		@"faver": @"user",
		@"faveDate": @"created_at",
        @"faveId": @"faveId",
	};
}

+ (NSValueTransformer *)faverJSONTransformer {
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ExploreUser.class];
}

+ (NSValueTransformer *)faveDateJSONTransformer {
    static NSISO8601DateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSISO8601DateFormatter alloc] init];
    });

    return [MTLValueTransformer transformerWithBlock:^id(id dateString) {
        return [_dateFormatter dateFromString:dateString];
    }];
}


#pragma mark - Fave Visualization

- (NSURL *)userIconUrl {
	return self.faver.userIcon;
}

- (NSInteger)userId {
	return self.faver.userId;
}

- (NSDate *)createdAt {
    return self.faveDate;
}

- (NSString *)userName {
	return self.faver.login;
}

@end
