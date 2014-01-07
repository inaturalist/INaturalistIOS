//
//  User.m
//  iNaturalist
//
//  Created by Ryan Waggoner on 10/5/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import "User.h"
#import "Comment.h"
#import "Identification.h"

static RKManagedObjectMapping *defaultMapping = nil;

@implementation User

@dynamic recordID;
@dynamic login;
@dynamic name;
@dynamic userIconURL;
@dynamic comments;
@dynamic identifications;

+ (RKManagedObjectMapping *)mapping
{
    if (!defaultMapping) {
        defaultMapping = [RKManagedObjectMapping mappingForClass:[User class]
                                            inManagedObjectStore:[RKManagedObjectStore defaultObjectStore]];
        [defaultMapping mapKeyPathsToAttributes:
         @"id", @"recordID",
         @"login", @"login",
         @"name", @"name",
		 @"user_icon_url", @"userIconURL",
         nil];
        defaultMapping.primaryKeyAttribute = @"recordID";
    }
    return defaultMapping;
}

@end