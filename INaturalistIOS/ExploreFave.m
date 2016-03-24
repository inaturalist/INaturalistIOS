//
//  ExploreFave.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/8/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ExploreFave.h"

@implementation ExploreFave

- (NSURL *)userIconUrl {
    return [NSURL URLWithString:self.faverIconUrl];
}

- (NSInteger)userId {
    return self.faverId;
}

- (NSDate *)createdAt {
    return self.faveDate;
}

- (NSString *)userName {
    return self.faverName;
}

@end
