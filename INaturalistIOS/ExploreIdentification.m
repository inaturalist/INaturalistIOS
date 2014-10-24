//
//  ExploreIdentification.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/10/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreIdentification.h"

@implementation ExploreIdentification

- (NSDate *)date {
    return self.identifiedDate;
}

- (BOOL)validateIdentificationId:(id *)ioValue error:(NSError **)outError {
    // Reject a identifiation ID of zero. By returning NO, we refused the assignment and the value will not be set
    if ([(NSNumber*)*ioValue intValue] == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateIdentificationTaxonId:(id *)ioValue error:(NSError **)outError {
    // Reject a identification taxon ID of zero. By returning NO, we refused the assignment and the value will not be set
    if ([(NSNumber*)*ioValue intValue] == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateIdentifierId:(id *)ioValue error:(NSError **)outError {
    // Reject a identifier ID of zero. By returning NO, we refused the assignment and the value will not be set
    if ([(NSNumber*)*ioValue intValue] == 0) {
        return NO;
    }
    
    return YES;
}

@end
