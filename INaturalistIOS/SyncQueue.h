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

@protocol SyncQueueDelegate <NSObject>
@optional
- (void)syncQueueStartedSyncFor:(id)model;
- (void)syncQueueFinishedSyncFor:(id)model;
- (void)syncQueueSynced:(INatModel *)record number:(NSInteger)number of:(NSInteger)total;
- (void)syncQueue:(SyncQueue *)syncQueue objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error;
- (void)syncQueueUnexpectedResponse;
- (void)syncQueueAuthRequired;
- (void)syncQueueFinished;
@end

/**
 * Queue of INatModels to sync with the server. Ensures that records of each
 * model are fully * synced before moving on to the next model.
 */
@interface SyncQueue : NSObject <RKObjectLoaderDelegate, RKRequestQueueDelegate, RKRequestDelegate>
@property (nonatomic, strong) NSMutableArray *queue;
@property (nonatomic, weak) id delegate;
@property (nonatomic, strong) RKObjectLoader *loader;
- (id)initWithDelegate:(id)delegate;

/**
 * Add model to the queue, e.g. [sq addModel:Observation.class]
 */
- (void)addModel:(id)model;

/**
 * Add model to the queue with optional selector to fire on the delegate to
 * actually perform the sync operation. Useful for appending extra params like
 * file data.
 */
- (void)addModel:(id)model syncSelector:(SEL)syncSelector;
- (void)start;
- (void)startDelete;
- (void)stop;
- (void)finish;
@end