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
