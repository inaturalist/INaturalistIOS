//
//  UploadManager.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/20/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

#import "UploadManager.h"
#import "INatModel.h"
#import "DeletedRecord.h"
#import "Observation.h"
#import "Analytics.h"
#import "ObservationPhoto.h"
#import "ObservationFieldValue.h"
#import "ProjectObservation.h"
#import "INaturalistAppDelegate.h"
#import "Project.h"
#import "LoginController.h"
#import "NSURL+INaturalist.h"
#import "ImageStore.h"
#import "UploadObservationOperation.h"
#import "DeleteRecordOperation.h"

static NSString *kQueueOperationCountChanged = @"kQueueOperationCountChanged";

@interface UploadManager () {
    Observation *_currentlyUploadingObservation;
    NSInteger _currentUploadSessionTotalObservations;
}

@property NSMutableArray *observationsToUpload;
@property NSMutableArray *recordsToDelete;
@property AFNetworkReachabilityManager *reachabilityMgr;
@property NSMutableDictionary *startTimesForPhotoUploads;
@property NSMutableDictionary *photoUploads;
@property NSDate *lastNetworkOutageNotificationDate;

// workaround for restkit bug
@property NSMutableArray *objectLoaders;
@property AFHTTPSessionManager *sessionManager;
@property NSInteger currentSessionTotalToUpload;
@property NSInteger currentSessionTotalUploaded;
@property NSMutableDictionary *uploadTasksProgress;

@property NSOperationQueue *uploadQueue;
@property NSOperationQueue *deleteQueue;
@end

@implementation UploadManager

#pragma mark - public methods

/**
 * Public method that serially uploads a list of observations.
 */
- (void)uploadObservations:(NSArray *)observations {
    self.observationsToUpload = [observations mutableCopy];
    _currentUploadSessionTotalObservations = self.observationsToUpload.count;
    
    self.sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL inat_baseURL]];
    [self.sessionManager.requestSerializer setValue:[[NSUserDefaults standardUserDefaults] stringForKey:INatTokenPrefKey]
                                 forHTTPHeaderField:@"Authorization"];
    [self syncUploads];
}

/**
 * Public method that serially syncs/uploads a list of deleted records,
 * then uploads a list of new or updated observations.
 */
- (void)syncDeletedRecords:(NSArray *)deletedRecords thenUploadObservations:(NSArray *)recordsToUpload {
    self.cancelled = NO;
    self.recordsToDelete = [deletedRecords mutableCopy];
    
    self.observationsToUpload = [recordsToUpload mutableCopy];
    _currentUploadSessionTotalObservations = self.observationsToUpload.count;
    
    self.sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL inat_baseURL]];
    [self.sessionManager.requestSerializer setValue:[[NSUserDefaults standardUserDefaults] stringForKey:INatTokenPrefKey]
                                 forHTTPHeaderField:@"Authorization"];
    
    if (self.recordsToDelete.count > 0) {
        [self syncDeletes];
    } else {
        [self syncUploads];
    }
}

- (void)syncDeletes {
    if (self.syncingDeletes || self.isUploading) {
        return;
    }
    
    for (DeletedRecord *dr in self.recordsToDelete) {
        DeleteRecordOperation *op = [[DeleteRecordOperation alloc] init];
        op.rootObjectId = dr.objectID;
        op.sessionManager = self.sessionManager;
        op.delegate = self.delegate;
        [self.deleteQueue addOperation:op];
    }
}

- (void)syncUploads {
    if (self.syncingDeletes || self.isUploading) {
        return;
    }
    
    for (Observation *o in self.observationsToUpload) {
        UploadObservationOperation *op = [[UploadObservationOperation alloc] init];
        op.rootObjectId = o.objectID;
        op.sessionManager = self.sessionManager;
        op.delegate = self.delegate;
        [self.uploadQueue addOperation:op];
    }
}

- (void)cancelSyncsAndUploads {
    // can't cancel if we're not actually doing anything
    if (!self.syncingDeletes && !self.isUploading) { return; }
    
    [self.deleteQueue cancelAllOperations];
    [self.uploadQueue cancelAllOperations];
    
    self.cancelled = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate uploadManager:self cancelledFor:nil];
    });
}

- (void)autouploadPendingContent {
    [self autouploadPendingContentExcludeInvalids:NO];
}

- (BOOL)currentUploadWorkContainsObservation:(Observation *)observation {
    return [self.observationsToUpload containsObject:observation];
}

#pragma mark - private methods

/*
 Upload all pending content. The exclude flag allows us to exclude any pending
 content that failed to upload last time due to server-side data validation issues.
 */
- (void)autouploadPendingContentExcludeInvalids:(BOOL)excludeInvalids {
    if (!self.shouldAutoupload) { return; }
    if (self.isUploading) { return; }
    
    NSMutableArray *recordsToDelete = [NSMutableArray array];
    for (Class klass in @[ [Observation class], [ObservationPhoto class], [ObservationFieldValue class], [ProjectObservation class] ]) {
        [recordsToDelete addObjectsFromArray:[DeletedRecord objectsWithPredicate:[NSPredicate predicateWithFormat:@"modelName = %@", \
                                                                                  NSStringFromClass(klass)]]];
    }
    
    // invalid observations failed validation their last upload
    NSPredicate *noInvalids = [NSPredicate predicateWithBlock:^BOOL(Observation *observation, NSDictionary *bindings) {
        return !(observation.validationErrorMsg && observation.validationErrorMsg.length > 0);
    }];
    
    NSArray *observationsToUpload = [Observation needingUpload];
    if (excludeInvalids) {
        observationsToUpload = [observationsToUpload filteredArrayUsingPredicate:noInvalids];
    }
    
    if (recordsToDelete.count > 0 || observationsToUpload.count > 0) {
        
        [[Analytics sharedClient] event:kAnalyticsEventSyncObservation
                         withProperties:@{
                                          @"Via": @"Automatic Upload",
                                          @"numDeletes": @(recordsToDelete.count),
                                          @"numUploads": @(observationsToUpload.count),
                                          }];
        
        [self syncDeletedRecords:recordsToDelete
          thenUploadObservations:observationsToUpload];
    }
}

- (void)stopUploadActivity {
    
    [self.sessionManager invalidateSessionCancelingTasks:YES];
}

#pragma mark - NSObject lifecycle

- (instancetype)init {
    if (self = [super init]) {
        // monitor reachability to trigger autoupload
        
        self.reachabilityMgr = [AFNetworkReachabilityManager managerForDomain:[[NSURL inat_baseURL] host]];
        [self.reachabilityMgr startMonitoring];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityChanged:)
                                                     name:AFNetworkingReachabilityDidChangeNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(loggedIn)
                                                     name:kINatLoggedInNotificationKey
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(observationUploadStartedNote:)
                                                     name:@"INatUploadStarted"
                                                   object:nil];

        
        self.startTimesForPhotoUploads = [[NSMutableDictionary alloc] init];
        self.photoUploads = [[NSMutableDictionary alloc] init];
        
        self.sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL inat_baseURL]];
        [self.sessionManager.requestSerializer setValue:[[NSUserDefaults standardUserDefaults] stringForKey:INatTokenPrefKey]
                                     forHTTPHeaderField:@"Authorization"];
        
        self.uploadTasksProgress = [NSMutableDictionary dictionary];
        
        self.uploadQueue = [[NSOperationQueue alloc] init];
        self.uploadQueue.name = @"Upload Queue";
        self.uploadQueue.maxConcurrentOperationCount = 1;
        [self.uploadQueue addObserver:self
                           forKeyPath:@"operationCount"
                              options:0
                              context:&kQueueOperationCountChanged];

        self.deleteQueue = [[NSOperationQueue alloc] init];
        self.deleteQueue.name = @"Delete Queue";
        self.deleteQueue.maxConcurrentOperationCount = 1;
        [self.deleteQueue addObserver:self
                           forKeyPath:@"operationCount"
                              options:0
                              context:&kQueueOperationCountChanged];

    }
    
    return self;
}

- (void)dealloc {
    [self.deleteQueue removeObserver:self forKeyPath:@"operationCount"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.sessionManager invalidateSessionCancelingTasks:YES];
}

#pragma mark - KVO of operation queues

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                         change:(NSDictionary *)change context:(void *)context
{
    if (object == self.deleteQueue && [keyPath isEqualToString:@"operationCount"] && context == &kQueueOperationCountChanged) {
        if ([self.deleteQueue.operations count] == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self delegate] uploadManagerDeleteSessionFinished:self];
            });
            if (self.observationsToUpload.count > 0) {
                [self syncUploads];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[self delegate] uploadManagerUploadSessionFinished:self];
                    [self stopUploadActivity];
                });
            }
        }
    } else if (object == self.uploadQueue && [keyPath isEqualToString:@"operationCount"] && context == &kQueueOperationCountChanged) {
        if ([self.uploadQueue.operations count] == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self delegate] uploadManagerUploadSessionFinished:self];
                [self stopUploadActivity];
            });
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object
                               change:change context:context];
    }
}


#pragma mark - NSNotification targets

- (void)loggedIn {
    // if there are any deleted records around,
    // they're stale and should be trashed
    for (DeletedRecord *record in [DeletedRecord allObjects]) {
        [record deleteEntity];
    }
    NSError *error = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
    if (error) {
        [[Analytics sharedClient] debugLog:@"Object Store Failed Removing Stale Deleted Records at Login"];
        [[Analytics sharedClient] debugLog:error.localizedDescription];
    }
}

- (void)observationUploadStartedNote:(NSNotification *)note {
    if ([note.name isEqualToString:@"INatUploadStarted"]) {
        if ([note.object isKindOfClass:[NSString class]]) {
            NSString *noteUuid = (NSString *)note.object;

            for (Observation *o in self.observationsToUpload) {
                if ([o.uuid isEqualToString:noteUuid]) {
                    self.currentlyUploadingObservation = o;
                }
            }
        }
    }

}

#pragma mark - Reachability Updates

- (void)reachabilityChanged:(NSNotification *)note {
    if ([note.object isEqual:self.reachabilityMgr]) {
        if (self.shouldAutoupload) {
            [self autouploadPendingContent];
        }
    }
}

#pragma mark - setters & getters

- (void)setCurrentlyUploadingObservation:(Observation *)currentlyUploadingObservation {
    _currentlyUploadingObservation = currentlyUploadingObservation;
}

- (Observation *)currentlyUploadingObservation {
    if (self.isUploading) {
        return _currentlyUploadingObservation;
    } else {
        return nil;
    }
}

- (NSInteger)indexOfCurrentlyUploadingObservation {
    if (self.isUploading) {
        NSInteger idx = self.currentUploadSessionTotalObservations - self.observationsToUpload.count;
        return idx;
    } else {
        return 0;
    }
}

- (NSInteger)currentUploadSessionTotalObservations {
    return _currentUploadSessionTotalObservations;
}

- (BOOL)shouldAutoupload {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!appDelegate.loginController.isLoggedIn)
        return NO;
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kInatAutouploadPrefKey])
        return NO;
    
    if ([self isUploading])
        return NO;
    
    // restkit hasn't finished loading yet
    if (![RKManagedObjectStore defaultObjectStore])
        return NO;
    
    return YES;
}

- (BOOL)isAutouploadEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kInatAutouploadPrefKey];
}

- (BOOL)isNetworkAvailableForUpload {
    return [self.reachabilityMgr isReachable];
}

- (BOOL)shouldNotifyAboutNetworkState {
    if (!self.lastNetworkOutageNotificationDate) {
        return YES;
    }
    
    NSTimeInterval timeSinceLastNotify = [[NSDate date] timeIntervalSinceDate:self.lastNetworkOutageNotificationDate];
    if (timeSinceLastNotify > 60 * 60 * 3) {
        // 3 hours
        return YES;
    }
    
    return NO;
}

- (void)notifiedAboutNetworkState {
    self.lastNetworkOutageNotificationDate = [NSDate date];
}

- (BOOL)isSyncingDeletes {
    return self.deleteQueue.operationCount > 0;
}

- (BOOL)isUploading {
    return self.uploadQueue.operationCount > 0;
}

@end
