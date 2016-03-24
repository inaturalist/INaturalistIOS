//
//  Identification.h
//  iNaturalist
//
//  Created by Ryan Waggoner on 10/5/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Activity.h"
#import "IdentificationVisualization.h"

@class Observation, Taxon, User;

@interface Identification : Activity <IdentificationVisualization>

@property (nonatomic, retain) NSNumber * recordID;
@property (nonatomic, retain) NSNumber * current;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSNumber * observationID;
@property (nonatomic, retain) NSNumber * taxonChangeID;
@property (nonatomic, retain) NSNumber * taxonID;
@property (nonatomic, retain) NSNumber * userID;
@property (nonatomic, retain) Taxon *taxon;

- (NSString *)createdAtPrettyString;
- (NSString *)createdAtShortString;
- (BOOL)isCurrent;

@end
