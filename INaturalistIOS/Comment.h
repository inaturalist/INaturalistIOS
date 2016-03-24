//
//  Comment.h
//  iNaturalist
//
//  Created by Ryan Waggoner on 10/5/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Activity.h"

#import "CommentVisualization.h"


@class Observation, User;

@interface Comment : Activity <CommentVisualization, ActivityVisualization>

@property (nonatomic, retain) NSNumber * recordID;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSNumber * parentID;
@property (nonatomic, retain) NSString * parentType;
@property (nonatomic, retain) NSNumber * userID;

- (NSString *)createdAtPrettyString;
- (NSString *)createdAtShortString;

@end