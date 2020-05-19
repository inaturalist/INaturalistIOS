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
@class ExploreObservationRealm;
@class ExploreDeletedRecord;

typedef NS_ENUM(NSInteger, UploadManagerState) {
    UploadManagerStateIdle,
    UploadManagerStateUploading,
    UploadManagerStateCancelling
};

@interface UploadManager : NSObject

@property (readonly) UploadManagerState state;

@property (assign, readonly) BOOL shouldNotifyAboutNetworkState;
- (void)notifiedAboutNetworkState;
@property (assign, readonly) BOOL isNetworkAvailableForUpload;

@property (assign, readonly) BOOL shouldAutoupload;
@property (assign, readonly) BOOL isAutouploadEnabled;

@property (nonatomic, weak) id <UploadManagerNotificationDelegate> delegate;

- (void)syncDeletedRecords:(NSArray <ExploreDeletedRecord *> *)deletedRecords thenUploadObservations:(NSArray <ExploreObservationRealm *> *)recordsToUpload;
- (void)uploadObservations:(NSArray <ExploreObservationRealm *> *)observations;
- (void)cancelSyncsAndUploads;
- (void)autouploadPendingContent;

@end
