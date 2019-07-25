//
//  SyncNotificationDelegate.h
//  iNaturalist
//
//  Created by Alex Shepard on 6/30/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ExploreObservationRealm;
@class Observation;
@class DeletedRecord;
@class UploadManager;

@protocol UploadManagerNotificationDelegate <NSObject>
- (void)uploadSessionStarted:(NSString *)observationUUID;
- (void)uploadSessionFinished;
- (void)uploadSessionProgress:(float)progress for:(NSString *)observationUUID;
- (void)uploadSessionSuccessFor:(NSString *)observationUUID;
- (void)uploadSessionFailedFor:(NSString *)observationUUID error:(NSError *)error;
- (void)uploadSessionCancelledFor:(NSString *)observationUUID;

- (void)deleteSessionStarted:(DeletedRecord *)deletedRecord;
- (void)deleteSessionFinished;
- (void)deleteSessionFailedFor:(DeletedRecord *)deletedRecord error:(NSError *)error;
@end
