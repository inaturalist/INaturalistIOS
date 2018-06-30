//
//  SyncNotificationDelegate.h
//  iNaturalist
//
//  Created by Alex Shepard on 6/30/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Observation;
@class DeletedRecord;
@class UploadManager;

@protocol UploadManagerNotificationDelegate <NSObject>
- (void)uploadSessionStarted:(Observation *)observation;
- (void)uploadSessionFinished;
- (void)uploadSessionProgress:(float)progress for:(Observation *)observation;
- (void)uploadSessionSuccessFor:(Observation *)observation;
- (void)uploadSessionFailedFor:(Observation *)observation error:(NSError *)error;
- (void)uploadSessionCancelledFor:(Observation *)observation;

- (void)deleteSessionStarted:(DeletedRecord *)deletedRecord;
- (void)deleteSessionFinished;
- (void)deleteSessionFailedFor:(DeletedRecord *)deletedRecord error:(NSError *)error;
@end
