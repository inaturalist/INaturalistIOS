//
//  Comment.h
//  iNaturalist
//
//  Created by Ryan Waggoner on 10/5/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "INatModel.h"

@class Observation, User;

@interface Comment : INatModel

@property (nonatomic, retain) NSNumber * recordID;
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSNumber * parentID;
@property (nonatomic, retain) NSString * parentType;
@property (nonatomic, retain) NSNumber * userID;
@property (nonatomic, retain) Observation *observation;
@property (nonatomic, retain) User *user;

- (NSString *)createdAtPrettyString;
- (NSString *)createdAtShortString;

@end