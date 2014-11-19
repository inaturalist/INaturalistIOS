//
//  SyncQueue.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/20/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@class INatModel;
@class SyncQueue;

typedef void(^LoaderConfigBlock)(RKObjectLoader *loader, INatModel *object);

@protocol SyncQueueNotificationDelegate <NSObject>
@optional
- (void)syncQueueStartedSyncFor:(Class)model;
- (void)syncQueueFinishedSyncFor:(Class)model;
- (void)syncQueueSynced:(Class)model number:(NSInteger)number of:(NSInteger)total;
- (void)syncQueueFailedForRecord:(INatModel *)failedSyncRecord withError:(NSError *)error;
- (void)syncQueueUnexpectedResponse;
- (void)syncQueueAuthRequired;
- (void)syncQueueFinished;
@end

/**
 * Queue of INatModels to sync with the server. Ensures that records of each
 * model are fully * synced before moving on to the next model.
 */
@interface SyncQueue : NSObject
@property (nonatomic, strong) NSMutableArray *queue;
@property (nonatomic, assign) id <SyncQueueNotificationDelegate> notificationDelegate;
@property (nonatomic, assign) BOOL started;

- (id)initWithDelegate:(id <SyncQueueNotificationDelegate>)delegate;

/**
 * Add model to the queue, e.g. [sq addModel:Observation.class]
 */
- (void)addModel:(id)model;

/**
 * Add model to the queue with optional block to configure the object loader
 * before performing the sync operation. Useful for appending extra params like
 * file data.
 */
- (void)addModel:(id)model loaderConfigBlock:(LoaderConfigBlock)block;
- (void)start;
- (void)stop;
- (void)finish;
- (BOOL)isRunning;
@end
