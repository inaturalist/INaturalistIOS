//
//  ProjectUser.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/12/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "INatModel.h"

@class Project;

@interface ProjectUser : INatModel

@property (nonatomic, retain) NSNumber * recordID;
@property (nonatomic, retain) NSDate * localUpdatedAt;
@property (nonatomic, retain) NSDate * localCreatedAt;
@property (nonatomic, retain) NSDate * syncedAt;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSNumber * projectID;
@property (nonatomic, retain) NSNumber * userID;
@property (nonatomic, retain) NSString * role;
@property (nonatomic, retain) NSNumber * observationsCount;
@property (nonatomic, retain) NSNumber * taxaCount;
@property (nonatomic, retain) NSString * userLogin;
@property (nonatomic, retain) Project * project;

@end
