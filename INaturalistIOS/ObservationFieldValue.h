//
//  ObservationFieldValue.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/12/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "INatModel.h"

@class Observation, ObservationField;

@interface ObservationFieldValue : INatModel

@property (nonatomic, retain) NSNumber * recordID;
@property (nonatomic, retain) NSNumber * observationID;
@property (nonatomic, retain) NSNumber * observationFieldID;
@property (nonatomic, retain) NSString * value;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSDate * localCreatedAt;
@property (nonatomic, retain) NSDate * localUpdatedAt;
@property (nonatomic, retain) ObservationField *observationField;
@property (nonatomic, retain) Observation *observation;

- (NSString *)defaultValue;
@end
