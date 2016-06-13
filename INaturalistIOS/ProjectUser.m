//
//  ProjectUser.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/12/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "ProjectUser.h"
#import "Project.h"

static RKManagedObjectMapping *defaultMapping = nil;
static RKManagedObjectMapping *defaultSerializationMapping = nil;

@implementation ProjectUser

@dynamic recordID;
@dynamic localUpdatedAt;
@dynamic localCreatedAt;
@dynamic syncedAt;
@dynamic createdAt;
@dynamic updatedAt;
@dynamic projectID;
@dynamic userID;
@dynamic role;
@dynamic observationsCount;
@dynamic taxaCount;
@dynamic userLogin;
@dynamic project;

+ (RKManagedObjectMapping *)mapping
{
    if (!defaultMapping) {
        defaultMapping = [RKManagedObjectMapping mappingForClass:[self class] inManagedObjectStore:[RKManagedObjectStore defaultObjectStore]];
        [defaultMapping mapKeyPathsToAttributes:
         @"id",         @"recordID",
         @"created_at", @"createdAt",
         @"updated_at", @"updatedAt",
         @"project_id", @"projectID",
         @"user_id",    @"userID",
         @"user.login", @"userLogin",
         @"role",       @"role",
         @"taxa_count", @"taxaCount",
         nil];
        [defaultMapping mapKeyPath:@"project" toRelationship:@"project" withMapping:[Project mapping]];
        defaultMapping.primaryKeyAttribute = @"recordID";
    }
    return defaultMapping;
}

+ (RKManagedObjectMapping *)serializationMapping
{
    if (!defaultSerializationMapping) {
        defaultSerializationMapping = [RKManagedObjectMapping mappingForClass:[self class] inManagedObjectStore:[RKManagedObjectStore defaultObjectStore]];
        [defaultSerializationMapping mapKeyPathsToAttributes:
         @"projectID",  @"project_id",
         @"userID",     @"user_id",
         @"role",       @"role",
         nil];
    }
    return defaultSerializationMapping;
}

@end
