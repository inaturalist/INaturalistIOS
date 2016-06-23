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
	};
}

+ (NSValueTransformer *)faverJSONTransformer {
	return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ExploreUser.class];
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
