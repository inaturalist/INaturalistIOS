//
//  ExplorePerson.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/13/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExplorePerson.h"

@implementation ExplorePerson

- (BOOL)validatePersonId:(id *)ioValue error:(NSError **)outError {
    // Reject a person ID of zero. By returning NO, we refused the assignment and the value will not be set
    if ([(NSNumber*)*ioValue intValue] == 0) {
        return NO;
    }
    
    return YES;
}

@end
