//
//  SyncQueue.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/20/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "SyncQueue.h"
#import "INatModel.h"
#import "DeletedRecord.h"
#import "Observation.h"

@interface ModelSyncQueue: NSObject
@property INatModel *model;
@property int needingSyncCount;
@property int syncedCount;
@property int deletedRecordCount;
@property (nonatomic, copy) LoaderConfigBlock loaderConfigBlock;
// convenience initializer
+ (instancetype)queueForModel:(INatModel *)model configBlock:(LoaderConfigBlock)loaderConfigBlock;
@end

@implementation SyncQueue
@synthesize queue = _queue;
@synthesize delegate = _delegate;
@synthesize started = _started;

- (id)initWithDelegate:(id)delegate
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        self.queue = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addModel:(id)model
{
    [self addModel:model loaderConfigBlock:nil];
}

- (void)addModel:(id)model loaderConfigBlock:(LoaderConfigBlock)block
{
    [self.queue addObject:[ModelSyncQueue queueForModel:model configBlock:block]];
}

- (void)start
{
    [RKObjectManager.sharedManager.client setAuthenticationType: RKRequestAuthenticationTypeNone];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    ModelSyncQueue *current = (ModelSyncQueue *)[self.queue firstObject];
    if (!current) {
        [self finish];
        return;
    }
    self.started = YES;
    
    // delete objects first
    if (current.deletedRecordCount > 0) {
        NSArray *deletedRecords = [DeletedRecord objectsWithPredicate:
                                   [NSPredicate predicateWithFormat:
                                    @"modelName = %@", NSStringFromClass([current.model class])]];
        for (DeletedRecord *dr in deletedRecords) {
            [[RKClient sharedClient] delete:[NSString stringWithFormat:@"/%@/%d",
                                             dr.modelName.underscore.pluralize,
                                             dr.recordID.intValue]
                                 usingBlock:^(RKRequest *request) {
                                     
                                     request.onDidLoadResponse = ^(RKResponse *response) {
                                         if (!self.started) return;
                                         
                                         current.deletedRecordCount--;
                                         
                                         // if we're done deleting
                                         if (current.deletedRecordCount <= 0) {
                                             // remove all deleted records locally
                                             for (DeletedRecord *dr in deletedRecords) {
                                                 [dr deleteEntity];
                                             }
                                             NSError *error = nil;
                                             [[NSManagedObjectContext defaultContext] save:&error];
                                             
                                             // move the queue forward
                                             [self start];
                                         }
                                     };
                                     
                                     request.onDidFailLoadWithError = ^(NSError *error) {
                                         [self stop];
                                         if ([self.delegate respondsToSelector:@selector(syncQueueUnexpectedResponse)]) {
                                             [self.delegate syncQueueUnexpectedResponse];
                                         }
                                     };
                                 }];
        }
        // once deletion is complete, sync will -start again
        return;
    }
    
    NSArray *recordsToSync = [[current.model class] needingSync];
    if (recordsToSync.count == 0) {
        [self.queue removeObject:current];
        if ([self.delegate respondsToSelector:@selector(syncQueueFinishedSyncFor:)]) {
            [self.delegate performSelector:@selector(syncQueueFinishedSyncFor:) withObject:current.model];
        }
        [self start];
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(syncQueueStartedSyncFor:)]) {
        [self.delegate performSelector:@selector(syncQueueStartedSyncFor:) withObject:current.model];
    }
    
    // manually applying mappings b/c PUT and POST responses return JSON without a root element,
    // e.g. {foo: 'bar'} instead of observation: {foo: 'bar'}, which RestKit apparently can't
    // deal with using the name of the model it just posted.
    for (INatModel *record in recordsToSync) {
        RKObjectLoaderBlock loaderBlock = ^(RKObjectLoader *loader) {
            
            // ObservationPhotos do additional work
            // configuring the object loader before the request is sent
            if (current.loaderConfigBlock) {
                current.loaderConfigBlock(loader, record);
            } else {
                loader.objectMapping = [[current.model class] mapping];
            }
            
            loader.onDidLoadObjects = ^(NSArray *objects) {
                if (objects.count == 0) return;
                
                NSDate *now = [NSDate date];
                INatModel *o;
                for (int i = 0; i < objects.count; i++) {
                    o = [objects objectAtIndex:i];
                    [o setSyncedAt:now];
                    
                    current.syncedCount++;
                    
                    if ([self.delegate respondsToSelector:@selector(syncQueueSynced:number:of:)]) {
                        [self.delegate syncQueueSynced:o
                                                number:current.syncedCount
                                                    of:current.needingSyncCount];
                    }
                }
                
                NSError *error = nil;
                [[[RKObjectManager sharedManager] objectStore] save:&error];
                
                if (current.syncedCount >= current.needingSyncCount) {
                    [self start];
                }
            };
            
            __weak typeof(loader) weakLoader = loader;
            loader.onDidFailWithError = ^(NSError *error) {
                __strong typeof(weakLoader) strongLoader = weakLoader;
                // was running into a bug in release build config where the object loader was
                // getting deallocated after handling an error.  This is a kludge.
                bool jsonParsingError = [error.domain isEqualToString:@"JKErrorDomain"] && error.code == -1;
                bool authFailure = [error.domain isEqualToString:@"NSURLErrorDomain"] && error.code == -1012;
                bool recordDeletedFromServer = (strongLoader.response.statusCode == 404 || strongLoader.response.statusCode == 410) &&
                strongLoader.method == RKRequestMethodPUT &&
                [strongLoader.sourceObject respondsToSelector:@selector(recordID)] &&
                [strongLoader.sourceObject performSelector:@selector(recordID)] != nil;
                
                if (jsonParsingError || authFailure) {
                    [self stop];
                    if ([self.delegate respondsToSelector:@selector(syncQueueAuthRequired)]) {
                        [self.delegate performSelector:@selector(syncQueueAuthRequired)];
                    }
                } else if (recordDeletedFromServer) {
                    // if it was in the sync queue there were local changes, so post it again
                    INatModel *record = (INatModel *)strongLoader.sourceObject;
                    [record setSyncedAt:nil];
                    [record setRecordID:nil];
                    [record save];
                } else if ([self.delegate respondsToSelector:@selector(syncQueue:objectLoader:didFailWithError:)]) {
                    [self.delegate syncQueue:self objectLoader:strongLoader didFailWithError:error];
                } else {
                    [self stop];
                }
                
                // even if it was an error the object was still handled, so update the
                // counter and move the queue forward if necessary
                current.syncedCount++;
                if (self.isRunning && current.syncedCount >= current.needingSyncCount) {
                    [self start];
                }
            };
            
            loader.onDidFailLoadWithError = ^(NSError *error) {
                __strong typeof(weakLoader) strongLoader = weakLoader;
                if (strongLoader.response.request.method != RKRequestMethodDELETE) return;
                [self stop];
            };
        };
        
        if (record.syncedAt) {
            [[RKObjectManager sharedManager] putObject:record usingBlock:loaderBlock];
        } else {
            [[RKObjectManager sharedManager] postObject:record usingBlock:loaderBlock];
        }
    }
}

- (void)stop
{
    self.started = NO;
    [[[[RKObjectManager sharedManager] client] requestQueue] cancelAllRequests];
    // sleep is ok now
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void)finish
{
    [self stop];
    if ([self.delegate respondsToSelector:@selector(syncQueueFinished)]) {
        [self.delegate performSelector:@selector(syncQueueFinished)];
    }
    NSNotification *syncNotification = [NSNotification notificationWithName:INatUserSavedObservationNotification object:nil];
    [[NSNotificationCenter defaultCenter] postNotification:syncNotification];
}

- (BOOL)isRunning
{
    return (self.started == YES);
}

@end



@implementation ModelSyncQueue

+ (instancetype)queueForModel:(INatModel *)model configBlock:(LoaderConfigBlock)loaderConfigBlock {
    ModelSyncQueue *new = [[ModelSyncQueue alloc] init];
    
    new.model = model;
    new.needingSyncCount = [[model class] needingSync].count;
    new.syncedCount = 0;
    new.deletedRecordCount = [[model class] deletedRecordCount];
    if (loaderConfigBlock)
        new.loaderConfigBlock = loaderConfigBlock;
    
    return new;
}

@end


