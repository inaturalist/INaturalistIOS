//
//  ProjectObservation.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/12/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "ProjectObservation.h"
#import "Project.h"
#import "Observation.h"
#import "ExploreDeletedRecord.h"

@implementation ProjectObservation

@dynamic localCreatedAt;
@dynamic localUpdatedAt;
@dynamic recordID;
@dynamic syncedAt;
@dynamic projectID;
@dynamic observationID;
@dynamic curatorIdentificationID;
@dynamic project;
@dynamic observation;

// checks the associated observation for its recordID
- (NSNumber *)observationID
{
    [self willAccessValueForKey:@"observationID"];
    if (self.observation && self.observation.recordID && (!self.primitiveObservationID || [self.primitiveObservationID intValue] == 0)) {
        [self setPrimitiveObservationID:self.observation.recordID];
    }
    [self didAccessValueForKey:@"observationID"];
    return [self primitiveObservationID];
}
- (NSNumber *)projectID
{
    [self willAccessValueForKey:@"projectID"];
    if (self.project && self.project.recordID && (!self.primitiveProjectID || [self.primitiveProjectID intValue] == 0)) {
        [self setPrimitiveProjectID:self.project.recordID];
    }
    [self didAccessValueForKey:@"projectID"];
    return [self primitiveProjectID];
}

- (void)prepareForDeletion {
    if (self.syncedAt && self.observation) {
        ExploreDeletedRecord *dr = [[ExploreDeletedRecord alloc] initWithRecordId:self.recordID.integerValue
                                                                        modelName:NSStringFromClass(self.class)];
        dr.endpointName = [self.class endpointName];
        dr.synced = NO;
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        [realm addObject:dr];
        [realm commitWriteTransaction];
    }
}

#pragma mark - Uploadable

+ (NSString *)endpointName {
    // for deleted record syncs and such
    return @"project_observations";
}

+ (NSArray *)needingUpload {
    // observations (the parent object) take care of this
    return @[];
}

- (BOOL)needsUpload {
    return self.needsSync;
}

- (NSArray *)childrenNeedingUpload {
    return @[];
}


- (NSDictionary *)uploadableRepresentation {
    NSDictionary *mapping = @{
                              @"projectID": @"project_id",
                              @"observationID": @"observation_id",
                              };
    
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    for (NSString *key in mapping) {
        if ([self valueForKey:key]) {
            NSString *mappedName = mapping[key];
            mutableParams[mappedName] = [self valueForKey:key];
        }
    }
    
    // return an immutable copy
    return [NSDictionary dictionaryWithDictionary:mutableParams];
}

@end
