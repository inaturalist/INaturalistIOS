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
#import "DeletedRecord.h"

static RKManagedObjectMapping *defaultMapping = nil;
static RKManagedObjectMapping *defaultSerializationMapping = nil;

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

+ (RKManagedObjectMapping *)mapping
{
    if (!defaultMapping) {
        defaultMapping = [RKManagedObjectMapping mappingForClass:[self class] inManagedObjectStore:[RKManagedObjectStore defaultObjectStore]];
        [defaultMapping mapKeyPathsToAttributes:
         @"id", @"recordID",
         @"created_at", @"createdAt",
         @"updated_at", @"updatedAt",
         @"project_id", @"projectID",
         @"observation_id", @"observationID",
         @"curator_identification_id", @"curatorIdentificationID",
         nil];
        [defaultMapping mapKeyPath:@"project"
                    toRelationship:@"project"
                       withMapping:[Project mapping]
                         serialize:NO];
        defaultMapping.primaryKeyAttribute = @"recordID";
    }
    return defaultMapping;
}

+ (RKManagedObjectMapping *)serializationMapping
{
    if (!defaultSerializationMapping) {
        defaultSerializationMapping = [RKManagedObjectMapping mappingForClass:[self class] inManagedObjectStore:[RKManagedObjectStore defaultObjectStore]];
        [defaultSerializationMapping mapKeyPathsToAttributes:
         @"projectID", @"project_observation[project_id]",
         @"observationID", @"project_observation[observation_id]",
         nil];
    }
    return defaultSerializationMapping;
}

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

- (void)prepareForDeletion
{
    if (self.syncedAt && self.observation) {
        DeletedRecord *dr = [DeletedRecord object];
        dr.recordID = self.recordID;
        dr.modelName = NSStringFromClass(self.class);
    }
}

@end
