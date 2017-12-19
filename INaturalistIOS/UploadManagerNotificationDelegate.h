//
//  SyncNotificationDelegate.h
//  iNaturalist
//
//  Created by Alex Shepard on 6/30/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@class INatModel;
@class Observation;
@class DeletedRecord;
@class UploadManager;

@protocol UploadManagerNotificationDelegate <NSObject>
- (void)uploadManagerSessionFailed:(UploadManager *)uploadManager errorCode:(NSInteger)httpErrorCode;

- (void)uploadManagerUploadSessionFinished:(UploadManager *)uploadManager;
- (void)uploadManager:(UploadManager *)uploadManager
     uploadStartedFor:(Observation *)observation
               number:(NSInteger)current
                   of:(NSInteger)total;
- (void)uploadManager:(UploadManager *)uploadManager
     uploadSuccessFor:(Observation *)observation;
- (void)uploadManager:(UploadManager *)uploadManager
       uploadProgress:(float)progress
                  for:(Observation *)observation;
- (void)uploadManager:(UploadManager *)uploadManager
            uploadFailedFor:(INatModel *)object
                error:(NSError *)error;
- (void)uploadManager:(UploadManager *)uploadManager
         cancelledFor:(INatModel *)object;

- (void)uploadManager:(UploadManager *)uploadManager nonFatalErrorForObservation:(Observation *)observation;

- (void)uploadManager:(UploadManager *)uploadManager
     deleteStartedFor:(DeletedRecord *)deletedRecord;
- (void)uploadManager:(UploadManager *)uploadManager
     deleteSuccessFor:(DeletedRecord *)deletedRecord;
- (void)uploadManagerDeleteSessionFinished:(UploadManager *)uploadManager;
- (void)uploadManager:(UploadManager *)uploadManager
      deleteFailedFor:(DeletedRecord *)deletedRecord
                error:(NSError *)error;
@end
