//
//  ExploreDeletedRecord.m
//  iNaturalist
//
//  Created by Alex Shepard on 8/21/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import "ExploreDeletedRecord.h"

@implementation ExploreDeletedRecord

- (instancetype)initWithRecordId:(NSInteger)recordId modelName:(NSString *)modelName {
    if (self = [super init]) {
        self.recordId = recordId;
        self.modelName = modelName;
        // synthetic primary key
        self.modelAndRecordId = [NSString stringWithFormat:@"%ld-%@", (long)self.recordId, self.modelName];
    }
    
    return self;
}

+ (NSString *)primaryKey {
    return @"modelAndRecordId";
}

+ (ExploreDeletedRecord *)deletedRecordId:(NSInteger)recordId withModelName:(NSString *)modelName {
    NSString *modelAndRecordId = [NSString stringWithFormat:@"%ld-%@", (long)recordId, modelName];
    return [self objectForPrimaryKey:modelAndRecordId];
}

+ (RLMResults *)syncedRecords {
    return [[self class] objectsWhere:@"synced == 1"];
}

+ (RLMResults *)needingSync {
    return [[self class] objectsWhere:@"synced == 0"];
}

+ (NSInteger)needingSyncCount {
    return [[self needingSync] count];
}

+ (RLMResults *)needingSyncForModelName:(NSString *)modelName {
    return [[self class] objectsWhere:@"synced == 0 AND modelName == %@", modelName];
}

@end
