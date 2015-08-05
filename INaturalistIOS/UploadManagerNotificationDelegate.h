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

@protocol UploadManagerNotificationDelegate <NSObject>
@optional
- (void)uploadSessionAuthRequired;
- (void)uploadSessionFinished;
- (void)uploadStartedFor:(Observation *)observation;
- (void)uploadSuccessFor:(Observation *)observation;

- (void)uploadFailedFor:(INatModel *)object error:(NSError *)error;

- (void)uploadNonFatalError:(NSError *)error;

- (void)deleteStartedFor:(DeletedRecord *)deletedRecord;
- (void)deleteSuccessFor:(DeletedRecord *)deletedRecord;
- (void)deleteSessionFinished;
- (void)deleteFailedFor:(DeletedRecord *)deletedRecord error:(NSError *)error;
@end
