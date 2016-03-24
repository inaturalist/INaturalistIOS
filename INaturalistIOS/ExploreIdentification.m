//
//  ExploreIdentification.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/10/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreIdentification.h"

@implementation ExploreIdentification

#pragma mark - ActivityVisualziation

- (NSDate *)createdAt {
    return self.identifiedDate;
}

#pragma mark - IdentificationVisualization

- (NSInteger)userId {
    return self.identifierId;
}

- (NSString *)body {
    return self.identificationBody;
}

- (NSDate *)date {
    return self.identifiedDate;
}

- (NSString *)userName {
    return self.identifierName;
}

- (NSURL *)userIconUrl {
    return [NSURL URLWithString:self.identifierIconUrl];
}

- (NSString *)taxonCommonName {
    return self.identificationCommonName;
}

- (NSString *)taxonScientificName {
    return self.identificationScientificName;
}

- (NSInteger)taxonId {
    return self.identificationTaxonId;
}

- (NSInteger)taxonRankLevel {
    return self.identificationTaxonRankLevel;
}

- (NSString *)taxonRank {
    return self.identificationTaxonRank;
}

- (NSURL *)taxonIconUrl {
    return [NSURL URLWithString:self.identificationPhotoUrlString];
}

- (BOOL)isCurrent {
    return self.identificationIsCurrent;
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

- (NSString *)description {
    return [NSString stringWithFormat:@"Explore Identification by %@ at %@.",
            self.userName, self.createdAt.description];
}


@end
