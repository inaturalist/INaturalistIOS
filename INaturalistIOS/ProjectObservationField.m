//
//  ProjectObservationField.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/12/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "ProjectObservationField.h"
#import "ObservationField.h"
#import "Project.h"

static RKManagedObjectMapping *defaultMapping = nil;
//static RKManagedObjectMapping *defaultSerializationMapping = nil;

@implementation ProjectObservationField

@dynamic recordID;
@dynamic projectID;
@dynamic observationFieldID;
@dynamic required;
@dynamic position;
@dynamic createdAt;
@dynamic updatedAt;
@dynamic localCreatedAt;
@dynamic localUpdatedAt;
@dynamic syncedAt;
@dynamic project;
@dynamic observationField;

+ (RKManagedObjectMapping *)mapping
{
    if (!defaultMapping) {
        defaultMapping = [RKManagedObjectMapping mappingForClass:[self class] inManagedObjectStore:[RKManagedObjectStore defaultObjectStore]];
        [defaultMapping mapKeyPathsToAttributes:
         @"id",                     @"recordID",
         @"created_at",             @"createdAt",
         @"updated_at",             @"updatedAt",
         @"project_id",             @"projectID",
         @"observation_field_id",   @"observationFieldID",
         @"required",               @"required",
         @"position",               @"position",
         nil];
        [defaultMapping mapKeyPath:@"observation_field" 
                    toRelationship:@"observationField" 
                       withMapping:[ObservationField mapping]
                         serialize:NO];
        defaultMapping.primaryKeyAttribute = @"recordID";
    }
    return defaultMapping;
}

+ (NSArray *)textFieldDataTypes {
    return @[ @"text", @"dna" ];
}

@end
