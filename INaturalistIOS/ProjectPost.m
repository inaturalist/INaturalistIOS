//
//  ProjectPost.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/14/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ProjectPost.h"
#import "User.h"

static RKManagedObjectMapping *defaultMapping = nil;

@implementation ProjectPost

@dynamic recordID;
@dynamic projectID;
@dynamic publishedAt;
@dynamic body;
@dynamic title;
@dynamic author;

+ (RKManagedObjectMapping *)mapping
{
    if (!defaultMapping) {
        
        defaultMapping = [RKManagedObjectMapping mappingForClass:[self class]
                                            inManagedObjectStore:[RKManagedObjectStore defaultObjectStore]];
        
        [defaultMapping mapKeyPath:@"id"
                       toAttribute:@"recordID"];
        [defaultMapping mapKeyPath:@"parent_id"
                       toAttribute:@"projectID"];
        [defaultMapping mapKeyPath:@"published_at"
                       toAttribute:@"publishedAt"];
        [defaultMapping mapKeyPath:@"body"
                       toAttribute:@"body"];
        [defaultMapping mapKeyPath:@"title"
                       toAttribute:@"title"];
        
        [defaultMapping mapKeyPath:@"user"
                    toRelationship:@"author"
                       withMapping:[User mapping]];
        
        defaultMapping.primaryKeyAttribute = @"recordID";
    }
    return defaultMapping;
}

- (void)setSyncedAt:(NSDate *)syncedAt {
    return;
}

- (NSDate *)syncedAt {
    return nil;
}


@end
