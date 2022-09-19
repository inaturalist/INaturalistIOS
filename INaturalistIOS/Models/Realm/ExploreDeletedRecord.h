//
//  ExploreDeletedRecord.h
//  iNaturalist
//
//  Created by Alex Shepard on 8/21/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>

@interface ExploreDeletedRecord : RLMObject

@property NSInteger recordId;
@property NSString *modelName;
@property NSString *endpointName;
@property BOOL synced;
// synthetic primary key
@property NSString *modelAndRecordId;

- (instancetype)initWithRecordId:(NSInteger)recordId modelName:(NSString *)modelName NS_DESIGNATED_INITIALIZER;

- (instancetype)init __attribute((unavailable));
- (instancetype)initWithValue:(id)value __attribute((unavailable));

+ (ExploreDeletedRecord *)deletedRecordId:(NSInteger)recordId withModelName:(NSString *)modelName;

+ (RLMResults *)syncedRecords;
+ (RLMResults *)needingSync;
+ (NSInteger)needingSyncCount;

+ (RLMResults *)needingSyncForModelName:(NSString *)modelName;

@end
