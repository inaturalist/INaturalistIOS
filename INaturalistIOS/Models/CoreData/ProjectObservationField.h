//
//  ProjectObservationField.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/12/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "INatModel.h"

@class ObservationField, Project;

@interface ProjectObservationField : INatModel

@property (nonatomic, retain) NSNumber * recordID;
@property (nonatomic, retain) NSNumber * projectID;
@property (nonatomic, retain) NSNumber * observationFieldID;
@property (nonatomic, retain) NSNumber * required;
@property (nonatomic, retain) NSNumber * position;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSDate * localCreatedAt;
@property (nonatomic, retain) NSDate * localUpdatedAt;
@property (nonatomic, retain) NSDate * syncedAt;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) ObservationField *observationField;

// datatypes that can just be treated as text
+ (NSArray *)textFieldDataTypes;

@end
