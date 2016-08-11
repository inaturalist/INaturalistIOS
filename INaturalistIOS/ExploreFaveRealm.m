//
//  ExploreFaveRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 8/9/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ExploreFaveRealm.h"

@implementation ExploreFaveRealm

- (instancetype)initWithMantleModel:(ExploreFave *)model {
	if (self = [super init]) {
		self.faveDate = model.faveDate;
		self.faver = [[ExploreUserRealm alloc] initWithMantleModel:model.faver];
	}
	
	return self;
}

- (NSURL *)userIconUrl {
    return self.faver.userIcon;
}

- (NSInteger)userId {
    return self.faver.userId;
}

- (NSString *)userName {
    return self.faver.login;
}

- (NSDate *)createdAt {
    return self.faveDate;
}

@end
