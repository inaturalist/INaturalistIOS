//
//  SpeciesCount.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "SpeciesCount.h"

@implementation SpeciesCount

- (BOOL)isGenusOrLower
{
    return (self.speciesRankLevel > 0 && self.speciesRankLevel <= 20);
}

@end
