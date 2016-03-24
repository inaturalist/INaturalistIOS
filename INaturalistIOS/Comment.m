//
//  Comment.m
//  iNaturalist
//
//  Created by Ryan Waggoner on 10/5/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import "Comment.h"
#import "Observation.h"
#import "User.h"

static RKManagedObjectMapping *defaultMapping = nil;
static RKObjectMapping *defaultSerializationMapping = nil;

@implementation Comment

@dynamic recordID;
@dynamic body;
@dynamic createdAt;
@dynamic updatedAt;
@dynamic parentID;
@dynamic parentType;
@dynamic userID;
@dynamic observation;
@dynamic user;

- (NSDate *)date {
    return self.createdAt;
}

- (NSString *)userName {
    return self.user.login;
}

- (NSURL *)userIconUrl {
    return [NSURL URLWithString:self.user.userIconURL];
}

+ (RKManagedObjectMapping *)mapping
{
    if (!defaultMapping) {
        defaultMapping = [RKManagedObjectMapping mappingForClass:[Comment class]
                                            inManagedObjectStore:[RKManagedObjectStore defaultObjectStore]];
        [defaultMapping mapKeyPathsToAttributes:
         @"id", @"recordID",
         @"body", @"body",
		 @"created_at", @"createdAt",
		 @"updated_at", @"updatedAt",
         @"parent_id", @"parentID",
         @"parent_type", @"parentType",
         @"user_id", @"userID",
         nil];
		[defaultMapping mapKeyPath:@"user"
                    toRelationship:@"user"
                       withMapping:[User mapping]
                         serialize:NO];
        defaultMapping.primaryKeyAttribute = @"recordID";
    }
    return defaultMapping;
}

+ (RKObjectMapping *)serializationMapping
{
    if (!defaultSerializationMapping) {
        defaultSerializationMapping = [[RKManagedObjectMapping mappingForClass:[Comment class]
                                                          inManagedObjectStore:[RKManagedObjectStore defaultObjectStore]] inverseMapping];
        [defaultSerializationMapping mapKeyPathsToAttributes:
         @"parentType", @"identification[parent_type]",
         @"parentID", @"identification[parent_id]",
		 @"body", @"identification[body]",
         nil];
    }
    return defaultSerializationMapping;
}

- (NSString *)createdAtPrettyString
{
    if (!self.createdAt) return @"Unknown";
    return [Comment.prettyDateFormatter stringFromDate:self.createdAt];
}

- (NSString *)createdAtShortString
{
    if (!self.createdAt) return @"Unknown";
    return [Comment.shortDateFormatter stringFromDate:self.createdAt];
}


@end