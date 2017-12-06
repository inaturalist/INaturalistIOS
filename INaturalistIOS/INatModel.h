//
//  INatModel.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/20/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <CoreData/CoreData.h>

@interface INatModel : NSManagedObject

@property (nonatomic, retain) NSNumber * recordID;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSDate * localCreatedAt;
@property (nonatomic, retain) NSDate * localUpdatedAt;
@property (nonatomic, retain) NSDate * syncedAt;

+ (NSDateFormatter *)prettyDateFormatter;
+ (NSDateFormatter *)shortDateFormatter;
+ (NSDateFormatter *)isoDateFormatter;
+ (NSDateFormatter *)jsDateFormatter;
+ (NSArray *)matchingRecordIDs:(NSArray *)recordIDs;
+ (NSArray *)all;
+ (NSArray *)needingSync;
+ (NSFetchRequest *)needingSyncRequest;
+ (NSInteger)needingSyncCount;
+ (NSInteger)deletedRecordCount;
+ (id)stub;
+ (RKManagedObjectMapping *)mapping;
+ (RKObjectMapping *)serializationMapping;
+ (void)deleteAll;
+ (NSManagedObjectContext *)managedObjectContext;
- (void)save;
- (void)destroy;
- (BOOL)needsSync;
- (void)updateLocalTimestamps;
- (NSDictionary *)attributeChanges;
@end
