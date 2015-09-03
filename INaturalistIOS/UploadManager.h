//
//  UploadManager.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/20/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UploadManagerNotificationDelegate.h"

@class INatModel;

@interface UploadManager : NSObject

@property (assign, getter=isCancelled) BOOL cancelled;
@property (assign, getter=isUploading) BOOL uploading;
@property (assign, getter=isSyncingDeletes) BOOL syncingDeletes;

@property Observation *currentlyUploadingObservation;

// index counting from zero
@property (readonly) NSInteger indexOfCurrentlyUploadingObservation;

@property (readonly) NSInteger currentUploadSessionTotalObservations;

@property (nonatomic, weak) id <UploadManagerNotificationDelegate> delegate;

- (void)syncDeletedRecords:(NSArray *)deletedRecords thenUploadObservations:(NSArray *)recordsToUpload;
- (void)uploadObservations:(NSArray *)observations;
- (void)cancelSyncsAndUploads;

@end