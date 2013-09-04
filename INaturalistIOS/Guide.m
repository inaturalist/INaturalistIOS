//
//  Guide.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/1/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import "Guide.h"
#import "List.h"

static RKManagedObjectMapping *defaultMapping = nil;

@implementation Guide

@dynamic title;
@dynamic desc;
@dynamic createdAt;
@dynamic updatedAt;
@dynamic iconURL;
@dynamic localCreatedAt;
@dynamic localUpdatedAt;
@dynamic syncedAt;
@dynamic recordID;
@dynamic taxonID;
@dynamic latitude;
@dynamic longitude;
@dynamic taxon;

+ (RKManagedObjectMapping *)mapping
{
    if (!defaultMapping) {
        defaultMapping = [RKManagedObjectMapping mappingForClass:[self class] inManagedObjectStore:[RKManagedObjectStore defaultObjectStore]];
        [defaultMapping mapKeyPathsToAttributes:
         @"id", @"recordID",
         @"created_at", @"createdAt",
         @"updated_at", @"updatedAt",
         @"title", @"title",
         @"description", @"desc",
         @"icon_url", @"iconURL",
         @"taxon_id", @"taxonID",
         @"user_id", @"userID",
         @"user_login", @"userLogin",
         @"latitude", @"latitude",
         @"longitude", @"longitude",
         nil];
        [defaultMapping mapKeyPath:@"taxon"
                    toRelationship:@"taxon"
                       withMapping:[Taxon mapping]
                         serialize:NO];
        defaultMapping.primaryKeyAttribute = @"recordID";
    }
    return defaultMapping;
}

@end
