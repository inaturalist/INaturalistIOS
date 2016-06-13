//
//  Identification.h
//  iNaturalist
//
//  Created by Ryan Waggoner on 10/5/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "INatModel.h"

@class Observation, Taxon, User;

@interface Identification : INatModel

@property (nonatomic, retain) NSNumber * recordID;
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSNumber * current;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSNumber * observationID;
@property (nonatomic, retain) NSNumber * taxonChangeID;
@property (nonatomic, retain) NSNumber * taxonID;
@property (nonatomic, retain) NSNumber * userID;
@property (nonatomic, retain) Observation *observation;
@property (nonatomic, retain) Taxon *taxon;
@property (nonatomic, retain) User *user;

- (NSString *)createdAtPrettyString;
- (NSString *)createdAtShortString;
- (BOOL)isCurrent;

@end
