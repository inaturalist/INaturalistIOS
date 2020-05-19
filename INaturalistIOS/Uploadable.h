//
//  Uploadable.h
//  iNaturalist
//
//  Created by Alex Shepard on 7/24/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol Uploadable <NSObject>

- (NSArray *)childrenNeedingUpload;
- (BOOL)needsUpload;
+ (NSArray *)needingUpload;
- (NSDictionary *)uploadableRepresentation;
- (NSString *)uuid;
+ (NSString *)endpointName;
- (NSDate *)timeSynced;
- (void)setTimeSynced:(NSDate *)date;
- (void)setRecordId:(NSInteger)newRecordId;
- (NSInteger)recordId;

@optional
- (NSString *)fileUploadParameter;
@end
