//
//  ExploreLocation.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/1/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreLocation.h"

@implementation ExploreLocation

- (NSString *)description {
    return [NSString stringWithFormat:@"ExploreLocation: %@ with type %ld", self.name, (long)self.type];
}

@end
