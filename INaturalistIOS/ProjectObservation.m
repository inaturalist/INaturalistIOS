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
        defaultMapping = [RKManagedObjectMapping mappingForClass:[self class]];
        [defaultMapping mapKeyPathsToAttributes:
         @"id", @"recordID",
         @"created_at", @"createdAt",
         @"updated_at", @"updatedAt",
         @"project_id", @"projectID",
         @"observation_id", @"observationID",
         @"curator_identification_id", @"curatorIdentificationID",
         nil];
        defaultMapping.primaryKeyAttribute = @"recordID";
    }
    return defaultMapping;
}

+ (RKManagedObjectMapping *)serializationMapping
{
    if (!defaultSerializationMapping) {
        defaultSerializationMapping = [RKManagedObjectMapping mappingForClass:[self class]];
        [defaultSerializationMapping mapKeyPathsToAttributes:
         @"projectID", @"project_id",
         @"observationID", @"observation_id",
         nil];
    }
    return defaultSerializationMapping;
}

@end
