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

- (BOOL)validateLocationId:(id *)ioValue error:(NSError **)outError {
    // Reject a location ID of zero. By returning NO, we refused the assignment and the value will not be set
    if ([(NSNumber*)*ioValue intValue] == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateType:(id *)ioValue error:(NSError **)outError {
    // Reject a type of zero. By returning NO, we refused the assignment and the value will not be set
    if ([(NSNumber*)*ioValue intValue] == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateLatitude:(id *)ioValue error:(NSError **)outError {
    // Reject a latitude of zero. By returning NO, we refused the assignment and the value will not be set
    if ([(NSNumber*)*ioValue intValue] == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateLongitude:(id *)ioValue error:(NSError **)outError {
    // Reject a longitude of zero. By returning NO, we refused the assignment and the value will not be set
    if ([(NSNumber*)*ioValue intValue] == 0) {
        return NO;
    }
    
    return YES;
}




@end
