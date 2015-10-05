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

@property (assign, readonly) BOOL shouldNotifyAboutNetworkState;
- (void)notifiedAboutNetworkState;
@property (assign, readonly) BOOL isNetworkAvailableForUpload;

@property (assign, readonly) BOOL shouldAutoupload;
@property (assign, readonly) BOOL isAutouploadEnabled;

@property Observation *currentlyUploadingObservation;

// index counting from zero
@property (readonly) NSInteger indexOfCurrentlyUploadingObservation;

@property (readonly) NSInteger currentUploadSessionTotalObservations;

@property (nonatomic, weak) id <UploadManagerNotificationDelegate> delegate;

- (void)syncDeletedRecords:(NSArray *)deletedRecords thenUploadObservations:(NSArray *)recordsToUpload;
- (void)uploadObservations:(NSArray *)observations;
- (void)cancelSyncsAndUploads;
- (void)autouploadPendingContent;
- (BOOL)currentUploadWorkContainsObservation:(Observation *)observation;

@end