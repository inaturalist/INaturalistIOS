//
//  ListedTaxon.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/12/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "INatModel.h"

@class List;

@interface ListedTaxon : INatModel

@property (nonatomic, retain) NSNumber * recordID;
@property (nonatomic, retain) NSNumber * listID;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSDate * localCreatedAt;
@property (nonatomic, retain) NSDate * localUpdatedAt;
@property (nonatomic, retain) NSDate * syncedAt;
@property (nonatomic, retain) NSNumber * taxonID;
@property (nonatomic, retain) NSNumber * firstObservationID;
@property (nonatomic, retain) NSNumber * lastObservationID;
@property (nonatomic, retain) NSString * occurrenceStatus;
@property (nonatomic, retain) NSString * establishmentMeans;
@property (nonatomic, retain) NSString * taxonName;
@property (nonatomic, retain) NSString * taxonDefaultName;
@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * ancestry;
@property (nonatomic, retain) NSNumber * placeID;
@property (nonatomic, retain) List *list;

@end
