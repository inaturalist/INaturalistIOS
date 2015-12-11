//
//  User.h
//  iNaturalist
//
//  Created by Ryan Waggoner on 10/5/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "INatModel.h"

@class Comment;

@interface User : INatModel

@property (nonatomic, retain) NSNumber * recordID;
@property (nonatomic, retain) NSString * login;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * userIconURL;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) NSSet *identifications;
@property (nonatomic, retain) NSNumber * observationsCount;
@property (nonatomic, retain) NSNumber * identificationsCount;
@property (nonatomic, retain) NSString * mediumUserIconURL;
@property (nonatomic, retain) NSNumber * siteId;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addCommentsObject:(Comment *)value;
- (void)removeCommentsObject:(Comment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

- (void)addIdentificationsObject:(NSManagedObject *)value;
- (void)removeIdentificationsObject:(NSManagedObject *)value;
- (void)addIdentifications:(NSSet *)values;
- (void)removeIdentifications:(NSSet *)values;

@end