//
//  ExploreObservation.m
//  Explore Prototype
//
//  Created by Alex Shepard on 9/9/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreObservation.h"
#import "ExploreComment.h"
#import "ExploreIdentification.h"
#import "ExploreFave.h"

@interface ExploreObservation () {
    CLLocationDegrees _latitude;
    CLLocationDegrees _longitude;
}
@end

@implementation ExploreObservation

#pragma mark - Uploadable

- (NSArray *)childrenNeedingUpload {
    return @[];
}

- (BOOL)needsUpload {
    return false;
}

+ (NSArray *)needingUpload {
    return @[];
}

#pragma mark - ObservationVisualization

- (BOOL)isEditable {
    return NO;
}

- (NSNumber *)latitude {
    if (!self.locationCoordinateString) {
        return nil;
    }
    NSString *latString = [[self.locationCoordinateString componentsSeparatedByString:@","] firstObject];
    return @([latString floatValue]);
}

- (NSNumber *)longitude {
    if (!self.locationCoordinateString) {
        return nil;
    }
    NSString *lonString = [[self.locationCoordinateString componentsSeparatedByString:@","] lastObject];
    return @([lonString floatValue]);
}

- (NSString *)username {
    return self.observerName;
}

- (NSString *)userThumbUrl {
    return self.observerIconUrl;
}

- (NSNumber *)privateLatitude {
    return @(0);
}

- (NSNumber *)privateLongitude {
    return @(0);
}

- (NSNumber *)privatePositionalAccuracy {
    return @(0);
}

- (NSArray *)sortedFaves {
    return [self.faves sortedArrayUsingComparator:^NSComparisonResult(ExploreFave *obj1, ExploreFave *obj2) {
        // newest first
        return [obj2.faveDate compare:obj1.faveDate];
    }];
    return @[];
}

- (NSArray *)sortedActivity {
    NSArray *activity = [self.comments arrayByAddingObjectsFromArray:self.identifications];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:YES];
    NSArray *sortedActivity = [activity sortedArrayUsingDescriptors:@[ sortDescriptor ]];
    /*
    NSArray *sortedActivity = [activity sortedArrayUsingComparator:^NSComparisonResult(id <ActivityVisualization> obj1, id  <ActivityVisualization> obj2) {
        NSDate *obj1Date = [obj1 createdAt];
        NSDate *obj2Date = [obj2 createdAt];
        NSLog(@"comparing %@ with %@", obj1Date, obj2Date);
        return [obj1Date compare:obj2Date];
    }];
     */
    
    return sortedActivity;
}

- (ObsDataQuality)dataQuality {
    if ([self.qualityGrade isEqualToString:@"research"]) {
        return ObsDataQualityResearch;
    } else if ([self.qualityGrade isEqualToString:@"needs_id"]) {
        return ObsDataQualityNeedsID;
    } else {
        // must be casual?
        return ObsDataQualityCasual;
    }
}

- (NSString *)observedOnShortString {
    static NSDateFormatter *formatter = nil;
    if (!formatter) {
        NSLog(@"Formatting");
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterShortStyle];
        [formatter setTimeStyle:NSDateFormatterNoStyle];
    }
    return [formatter stringFromDate:self.observedOn];
}

- (NSNumber *)inatRecordId {
    return @(self.observationId);
}

- (NSNumber *)hasUnviewedActivity {
    return @(NO);
}

- (NSNumber *)userID {
    return @(self.observerId);
}

- (NSString *)sortable {
    return [NSString stringWithFormat:@"%f", self.timeObservedAt.timeIntervalSinceNow];
}

- (NSString *)uuid {
    // TODO: fetch uuid
    return  [[[NSUUID alloc] init] UUIDString];
}

- (NSNumber *)taxonID {
    return @(self.taxonId);
}

- (NSSet *)observationFieldValues {
    return [NSSet set];
}

- (NSNumber *)captive {
    return @(NO);
}

- (NSString *)validationErrorMsg {
    return @"";
}

- (NSString *)geoprivacy {
    return @"";
}

- (NSSet *)projectObservations {
    return [NSSet set];
}

- (NSArray *)sortedObservationPhotos {
    return self.observationPhotos;
}

- (NSNumber *)positionalAccuracy {
    return @(self.publicPositionalAccuracy);
}

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake(self.latitude.floatValue, self.longitude.floatValue);
}

- (NSString *)title {
    return nil;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"ExploreObservation: %@(%ld photos) at %f,%f", self.title, (unsigned long)self.observationPhotos.count, self.coordinate.latitude, self.coordinate.longitude];
}

// we're putting observations in a set, and want to make sure they don't get added more than once.
// so override -isEqual: and -hash to make observation objects unique to the underlying observation.
- (BOOL)isEqual:(id)object {
    if (![[object class] isEqual:self.class])
        return NO;
    ExploreObservation *otherObs = (ExploreObservation *)object;
    
    return self.observationId == otherObs.observationId;
}

-(NSUInteger)hash {
    return self.observationId;
}

- (BOOL)commentsAndIdentificationsSynchronized {
    if (self.commentsCount != self.comments.count)
        return NO;
    if (self.identificationsCount != self.identifications.count)
        return NO;
    
    return YES;
}


- (BOOL)validateObservationId:(id *)ioValue error:(NSError **)outError {
    // Reject a observation id of zero. By returning NO, we refused the assignment and the value will not be set
    if ([(NSNumber*)*ioValue intValue] == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateLatitude:(id *)ioValue error:(NSError **)outError {
    // Reject a latitude of zero. By returning NO, we refused the assignment and the value will not be set
    /*
    if ([(NSNumber*)*ioValue intValue] == 0) {
        return NO;
    }
     */
    
    return YES;
}

- (BOOL)validateLongitude:(id *)ioValue error:(NSError **)outError {
    // Reject a longitude of zero. By returning NO, we refused the assignment and the value will not be set
    /*
    if ([(NSNumber*)*ioValue intValue] == 0) {
        return NO;
    }
     */
    
    return YES;
}

- (BOOL)validateObserverId:(id *)ioValue error:(NSError **)outError {
    // Reject a observer id of zero. By returning NO, we refused the assignment and the value will not be set
    if ([(NSNumber*)*ioValue intValue] == 0) {
        return NO;
    }
    
    return YES;
}


- (BOOL)validateIdentificationsCount:(id *)ioValue error:(NSError **)outError {
    // Reject a identifications count of zero. By returning NO, we refused the assignment and the value will not be set
    if ([(NSNumber*)*ioValue intValue] == 0) {
        return NO;
    }
    
    return YES;
}


- (BOOL)validateCommentsCount:(id *)ioValue error:(NSError **)outError {
    // Reject a comments count of zero. By returning NO, we refused the assignment and the value will not be set
    if ([(NSNumber*)*ioValue intValue] == 0) {
        return NO;
    }
    
    return YES;
}


- (BOOL)validatePublicPositionalAccuracy:(id *)ioValue error:(NSError **)outError {
    // Reject a accuracy of zero. By returning NO, we refused the assignment and the value will not be set
    if ([(NSNumber*)*ioValue intValue] == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateTaxonId:(id *)ioValue error:(NSError **)outError {
    // Reject a taxon id of zero. By returning NO, we refused the assignment and the value will not be set
    if ([(NSNumber*)*ioValue intValue] == 0) {
        return NO;
    }
    
    return YES;
}


@end
