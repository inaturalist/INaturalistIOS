//
//  ObservationField.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/12/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "INatModel.h"

@interface ObservationField : INatModel

@property (nonatomic, retain) NSNumber * recordID;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * datatype;
@property (nonatomic, retain) NSNumber * userID;
@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * allowedValues;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSDate * localCreatedAt;
@property (nonatomic, retain) NSDate * localUpdatedAt;
@property (nonatomic, retain) NSDate * syncedAt;
@property (nonatomic, retain) NSSet *observationFieldValues;
@property (nonatomic, retain) NSManagedObject *projectObservationFields;

- (NSArray *)allowedValuesArray;
@end

@interface ObservationField (CoreDataGeneratedAccessors)

- (void)addObservationFieldValuesObject:(NSManagedObject *)value;
- (void)removeObservationFieldValuesObject:(NSManagedObject *)value;
- (void)addObservationFieldValues:(NSSet *)values;
- (void)removeObservationFieldValues:(NSSet *)values;

@end
