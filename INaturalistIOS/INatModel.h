//
//  INatModel.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/20/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface INatModel : NSManagedObject

@property (nonatomic, retain) NSNumber * recordID;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSDate * localCreatedAt;
@property (nonatomic, retain) NSDate * localUpdatedAt;
@property (nonatomic, retain) NSDate * syncedAt;

+ (NSArray *)all;
+ (NSArray *)needingSync;
+ (NSFetchRequest *)needingSyncRequest;
+ (int)needingSyncCount;
+ (id)stub;
+ (RKManagedObjectMapping *)mapping;
+ (RKManagedObjectMapping *)serializationMapping;
+ (void)deleteAll;
- (void)save;
- (void)destroy;
- (BOOL)needsSync;
@end
