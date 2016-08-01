//
//  Project.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/12/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "INatModel.h"

@interface Project : INatModel

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * terms;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSString * iconURL;
@property (nonatomic, retain) NSString * projectType;
@property (nonatomic, retain) NSString * cachedSlug;
@property (nonatomic, retain) NSNumber * observedTaxaCount;
@property (nonatomic, retain) NSDate * localCreatedAt;
@property (nonatomic, retain) NSDate * localUpdatedAt;
@property (nonatomic, retain) NSDate * syncedAt;
@property (nonatomic, retain) NSNumber * recordID;
@property (nonatomic, retain) NSSet *projectObservations;
@property (nonatomic, retain) NSSet *projectObservationFields;
@property (nonatomic, retain) NSSet *projectUsers;
@property (nonatomic, retain) NSString *projectObservationRuleTerms;
@property (nonatomic, retain) NSDate * featuredAt;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString *group;
@property (nonatomic, retain) NSNumber *newsItemCount;

- (BOOL)observationsRestrictedToList;
- (NSArray *)sortedProjectObservationFields;

@end
