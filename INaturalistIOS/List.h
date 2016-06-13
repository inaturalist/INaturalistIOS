//
//  List.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/12/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "INatModel.h"

@interface List : INatModel

@property (nonatomic, retain) NSNumber * recordID;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSDate * localCreatedAt;
@property (nonatomic, retain) NSDate * localUpdatedAt;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSDate * syncedAt;
@property (nonatomic, retain) NSNumber * comprehensive;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSNumber * taxonID;
@property (nonatomic, retain) NSNumber * placeID;
@property (nonatomic, retain) NSNumber * projectID;
@property (nonatomic, retain) NSSet *listedTaxa;
@property (nonatomic, retain) NSManagedObject *project;
@end

@interface List (CoreDataGeneratedAccessors)

- (void)addListedTaxaObject:(NSManagedObject *)value;
- (void)removeListedTaxaObject:(NSManagedObject *)value;
- (void)addListedTaxa:(NSSet *)values;
- (void)removeListedTaxa:(NSSet *)values;

@end
