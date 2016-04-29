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

- (BOOL)validateSpeciesRankLevel:(id *)ioValue error:(NSError **)outError {
    // Reject a species rank level of zero. By returning NO, we refused the assignment and the value will not be set
    if ([(NSNumber*)*ioValue intValue] == 0) {
        return NO;
    }
    
    return YES;
}

@end
