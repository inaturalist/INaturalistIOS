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
#import "ExploreObservationRealm.h"
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
#import "ObservationAPI.h"
#import "ExploreUserRealm.h"
#import "ExploreDeletedRecord.h"

static NSString *kQueueOperationCountChanged = @"kQueueOperationCountChanged";

@interface UploadManager ()

@property NSMutableArray *observationUUIDsToUpload;
@property AFNetworkReachabilityManager *reachabilityMgr;
@property NSMutableDictionary *photoUploads;
@property NSDate *lastNetworkOutageNotificationDate;
@property (assign, getter=isCancelled) BOOL cancelled;

@property AFHTTPSessionManager *nodeSessionManager;
@property NSInteger currentSessionTotalToUpload;
@property NSInteger currentSessionTotalUploaded;
@property NSMutableDictionary *uploadTasksProgress;

@property NSOperationQueue *uploadQueue;
@property NSOperationQueue *deleteQueue;
@end

@implementation UploadManager

#pragma mark - public methods

/**
* Public method that serially syncs/uploads a list of deleted records,
* then uploads a list of new or updated observations.
*/
- (void)syncDeletedRecordsThenUploadObservations {
    self.cancelled = NO;
    self.observationUUIDsToUpload = [NSMutableArray array];
    for (ExploreObservationRealm *o in [self observationsNeedingUpload]) {
        if ([o uuid]) {
            [self.observationUUIDsToUpload addObject:[o uuid]];
        } else {
            NSError *error = [[NSError alloc] initWithDomain:@"org.inaturalist"
                                                        code:-1018
                                                    userInfo:@{ NSLocalizedDescriptionKey: @"observation with nil uuid" }];
            [self.delegate uploadSessionFailedFor:nil error:error];
            return;
        }
    }

    if (self.deletedRecordsNeedingSync.count > 0) {
        [self syncDeletes];
    } else {
        [self syncUploads];
    }
}

/**
 * Public method that serially uploads a list of observations.
 */
- (void)uploadObservations:(NSArray <ExploreObservationRealm *> *)observations {
    self.cancelled = NO;
    self.observationUUIDsToUpload = [NSMutableArray array];
    for (ExploreObservationRealm *o in observations) {
        [self.observationUUIDsToUpload addObject:[o uuid]];
    }
    [self syncUploads];
}

- (void)syncDeletes {
    if (self.state != UploadManagerStateIdle) {
        return;
    }
    
    self.cancelled = NO;
    
    __weak typeof(self)weakSelf = self;
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.loginController getJWTTokenSuccess:^(NSDictionary *info) {
        
        // setup node session manager
        NSURL *nodeApiHost = [NSURL URLWithString:@"https://api.inaturalist.org"];
        weakSelf.nodeSessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:nodeApiHost];
        // delete operations return no data
        weakSelf.nodeSessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        
        // set the authorization for the node session manager
        [weakSelf.nodeSessionManager.requestSerializer setValue:appDelegate.loginController.jwtToken
                                             forHTTPHeaderField:@"Authorization"];
        
        // add the delete jobs to the queue
        for (ExploreDeletedRecord *dr in self.deletedRecordsNeedingSync) {
            DeleteRecordOperation *op = [[DeleteRecordOperation alloc] init];
            
            op.endpointName = dr.endpointName;
            op.recordId = dr.recordId;
            op.modelName = dr.modelName;

            op.nodeSessionManager = weakSelf.nodeSessionManager;
            op.delegate = self.delegate;
            [self.deleteQueue addOperation:op];
        }
    } failure:^(NSError *error) {
        NSError *jwtFailedError = [NSError errorWithDomain:INatJWTFailureErrorDomain
                                                      code:error.code
                                                  userInfo:error.userInfo];
        [self.delegate deleteSessionFailedFor:nil error:jwtFailedError];
    }];
}

- (void)syncUploads {
    if (self.state != UploadManagerStateIdle) {
        return;
    }
    
    self.cancelled = NO;
    
    __weak typeof(self)weakSelf = self;
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.loginController getJWTTokenSuccess:^(NSDictionary *info) {
        
        // setup node session manager
        NSURL *nodeApiHost = [NSURL URLWithString:@"https://api.inaturalist.org"];
        weakSelf.nodeSessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:nodeApiHost];
        AFJSONRequestSerializer *serializer = [[AFJSONRequestSerializer alloc] init];
        [weakSelf.nodeSessionManager setRequestSerializer:serializer];
        
        // set the authorization for the rails session manager
        [weakSelf.nodeSessionManager.requestSerializer setValue:appDelegate.loginController.jwtToken
                                             forHTTPHeaderField:@"Authorization"];
        
        // add the observations to the queue
        for (NSString *obsUUID in self.observationUUIDsToUpload) {
            UploadObservationOperation *operation = [[UploadObservationOperation alloc] init];
            operation.rootObjectUUID = obsUUID;
            operation.userSiteId = appDelegate.loginController.meUserLocal.siteId;
            operation.nodeSessionManager = weakSelf.nodeSessionManager;
            operation.delegate = weakSelf.delegate;
            [weakSelf.uploadQueue addOperation:operation];
        }
    } failure:^(NSError *error) {
        NSError *jwtFailedError = [NSError errorWithDomain:INatJWTFailureErrorDomain
                                                      code:error.code
                                                  userInfo:error.userInfo];
        [self.delegate deleteSessionFailedFor:nil error:jwtFailedError];
    }];
}

- (void)cancelSyncsAndUploads {
    // can't cancel if we're not actually doing anything
    if (self.state != UploadManagerStateUploading) {
        return;
    }
    
    [self.deleteQueue cancelAllOperations];
    [self.uploadQueue cancelAllOperations];
    
    self.cancelled = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate uploadSessionCancelledFor:nil];
    });
}

- (void)autouploadPendingContent {
    [self autouploadPendingContentExcludeInvalids:NO];
}

/*
 Arrange deleted records. We need to delete in a specific order in order to avoid
 invalidation errors on the server. For example, a project may require certain fields
 or photos to be a member - deleting the fields or the photos before deleting the
 project observation will result in a 422 validation error from the server.
 
 This is a public method so that the UI can know if there are records to delete
 or not.
 */

- (NSArray *)deletedRecordsNeedingSync {
    // delete in a specific order
    NSMutableArray *recordsToDelete = [NSMutableArray array];
    for (NSString *modelName in @[ @"Observation", @"ProjectObservation", @"ObservationPhoto", @"ObservationFieldValue",  ]) {
        RLMResults *needingDelete = [ExploreDeletedRecord needingSyncForModelName:modelName];
        // convert to array and add to our list of all things to delete
        [recordsToDelete addObjectsFromArray:[needingDelete valueForKey:@"self"]];
    }
    return [NSArray arrayWithArray:recordsToDelete];
}

/*
 this is a public method so the UI can konw if there are records to upload or not.
 */
- (NSArray *)observationsNeedingUpload {
    return [ExploreObservationRealm needingUpload];
}

#pragma mark - private methods



/*
 Upload all pending content. The exclude flag allows us to exclude any pending
 content that failed to upload last time due to server-side data validation issues.
 */
- (void)autouploadPendingContentExcludeInvalids:(BOOL)excludeInvalids {
    if (!self.shouldAutoupload) { return; }
        
    // invalid observations failed validation their last upload
    NSPredicate *noInvalids = [NSPredicate predicateWithBlock:^BOOL(ExploreObservationRealm *observation, NSDictionary *bindings) {
        return !(observation.validationErrorMsg && observation.validationErrorMsg.length > 0);
    }];
    
    NSArray *observationsToUpload = [ExploreObservationRealm needingUpload];
    if (excludeInvalids) {
        observationsToUpload = [observationsToUpload filteredArrayUsingPredicate:noInvalids];
    }
    
    if (self.deletedRecordsNeedingSync.count > 0 || self.observationsNeedingUpload.count > 0) {
        [self syncDeletedRecordsThenUploadObservations];
    }
}

- (void)stopUploadActivity {
    [self.nodeSessionManager invalidateSessionCancelingTasks:YES];
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
                                                     name:kUserLoggedInNotificationName
                                                   object:nil];
        
        self.photoUploads = [[NSMutableDictionary alloc] init];
        
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
    
    [self.nodeSessionManager invalidateSessionCancelingTasks:YES];
}

#pragma mark - KVO of operation queues

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                         change:(NSDictionary *)change context:(void *)context
{
    if (object == self.deleteQueue && [keyPath isEqualToString:@"operationCount"] && context == &kQueueOperationCountChanged) {
        if (self.deleteQueue.operationCount == 0) {
            self.cancelled = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate deleteSessionFinished];
            });
            if (self.observationUUIDsToUpload.count > 0) {
                [self syncUploads];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate uploadSessionFinished];
                    [self stopUploadActivity];
                });
            }
        }
    } else if (object == self.uploadQueue && [keyPath isEqualToString:@"operationCount"] && context == &kQueueOperationCountChanged) {
        if (self.uploadQueue.operationCount == 0) {
            self.cancelled = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate uploadSessionFinished];
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
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm deleteObjects:[ExploreDeletedRecord allObjects]];
    [realm commitWriteTransaction];
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

- (BOOL)shouldAutoupload {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!appDelegate.loginController.isLoggedIn)
        return NO;
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kInatAutouploadPrefKey])
        return NO;
    
    // don't trigger autoupload if we're already uploading or cancelling
    if ([self state] != UploadManagerStateIdle)
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

- (UploadManagerState)state {
    if (self.cancelled) {
        return UploadManagerStateCancelling;
    } else if (self.deleteQueue.operationCount > 0) {
        return UploadManagerStateUploading;
    } else if (self.uploadQueue.operationCount > 0) {
        return UploadManagerStateUploading;
    } else {
        return UploadManagerStateIdle;
    }
}

@end
