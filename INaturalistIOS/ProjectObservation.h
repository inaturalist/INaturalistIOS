//
//  ProjectObservation.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/12/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "INatModel.h"

@class Project;
@class Observation;

@interface ProjectObservation : INatModel

@property (nonatomic, retain) NSDate * localCreatedAt;
@property (nonatomic, retain) NSDate * localUpdatedAt;
@property (nonatomic, retain) NSNumber * recordID;
@property (nonatomic, retain) NSDate * syncedAt;
@property (nonatomic, retain) NSNumber * projectID;
@property (nonatomic, retain) NSNumber * observationID;
@property (nonatomic, retain) NSNumber * curatorIdentificationID;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) Observation *observation;

@end

@interface ProjectObservation (PrimitiveAccessors)
- (NSNumber *)primitiveObservationID;
- (void)setPrimitiveObservationID:(NSNumber *)newObservationId;
- (NSNumber *)primitiveProjectID;
- (void)setPrimitiveProjectID:(NSNumber *)newProjectId;
@end
