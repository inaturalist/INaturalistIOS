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

@implementation SyncQueue
@synthesize queue = _queue;
@synthesize delegate = _delegate;
@synthesize loader = _loader;
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
    [self addModel:model syncSelector:nil];
}

- (void)addModel:(id)model syncSelector:(SEL)syncSelector
{
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              model, @"model", 
                              [NSNumber numberWithInt:[model needingSyncCount]], @"needingSyncCount",
                              [NSNumber numberWithInt:0], @"syncedCount",
                              [NSNumber numberWithInt:[model deletedRecordCount]], @"deletedRecordCount",
                              nil];
    if (syncSelector) [d setValue:NSStringFromSelector(syncSelector) forKey:@"syncSelector"];
    [self.queue addObject:d];    
}

- (void)start
{
    [RKObjectManager.sharedManager.client setAuthenticationType: RKRequestAuthenticationTypeNone];
//RKRequestAuthenticationTypeHTTPBasic;
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    if (self.queue.count == 0) {
        [self finish];
        return;
    }
    self.started = YES;
    NSMutableDictionary *current = self.queue.firstObject;
    if (!current) {
        [self stop];
        return;
    }

    id model = [current objectForKey:@"model"];
    NSInteger deletedRecordCount = [[current objectForKey:@"deletedRecordCount"] intValue];
    NSArray *recordsToSync = [model needingSync];
    
    // delete objects first
    if (deletedRecordCount > 0) {
        [self startDelete];
        return;
    }
    
    if (recordsToSync.count == 0) {
        [self.queue removeObject:current];
        if ([self.delegate respondsToSelector:@selector(syncQueueFinishedSyncFor:)]) {
            [self.delegate performSelector:@selector(syncQueueFinishedSyncFor:) withObject:model];
        }
        [self start];
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(syncQueueStartedSyncFor:)]) {
        [self.delegate performSelector:@selector(syncQueueStartedSyncFor:) withObject:model];
    }
    
    // manually applying mappings b/c PUT and POST responses return JSON without a root element, 
    // e.g. {foo: 'bar'} instead of observation: {foo: 'bar'}, which RestKit apparently can't 
    // deal with using the name of the model it just posted.
    for (INatModel *record in recordsToSync) {
        if ([current objectForKey:@"syncSelector"]) {
            SEL syncSelector = NSSelectorFromString([current objectForKey:@"syncSelector"]);
            if ([self.delegate respondsToSelector:syncSelector]) {
                [self.delegate performSelector:syncSelector withObject:record];
            }
        } else {
            if (record.syncedAt) {
                [[RKObjectManager sharedManager] putObject:record mapResponseWith:[model mapping] delegate:self];
            } else {
                [[RKObjectManager sharedManager] postObject:record mapResponseWith:[model mapping] delegate:self];
            }
        }
    }
}

- (void)startDelete
{
    NSMutableDictionary *current = self.queue.firstObject;
    if (!current) {
        [self stop];
        return;
    }
    id model = [current objectForKey:@"model"];
    NSArray *deletedRecords = [DeletedRecord objectsWithPredicate:
                               [NSPredicate predicateWithFormat:
                                @"modelName = %@", NSStringFromClass(model)]];
    for (DeletedRecord *dr in deletedRecords) {
        [[RKClient sharedClient] delete:[NSString stringWithFormat:@"/%@/%d", 
                                         dr.modelName.underscore.pluralize, 
                                         dr.recordID.intValue] 
                               delegate:self];
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

#pragma mark RKObjectLoaderDelegate methods
- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects {
    if (objects.count == 0) return;
    
    NSMutableDictionary *current = self.queue.firstObject;
    if (!current) {
        [self stop];
        return;
    }
    
    NSNumber *needingSyncCount = [current objectForKey:@"needingSyncCount"];
    NSNumber *syncedCount = [current objectForKey:@"syncedCount"];
    
    NSDate *now = [NSDate date];
    INatModel *o;
    for (int i = 0; i < objects.count; i++) {
        o = [objects objectAtIndex:i];
        [o setSyncedAt:now];
        
        if ([self.delegate respondsToSelector:@selector(syncQueueSynced:number:of:)]) {
            NSMethodSignature *sig = [[self.delegate class]
                                      instanceMethodSignatureForSelector:@selector(syncQueueSynced:number:of:)];
            NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
            NSInteger number = [syncedCount intValue] + 1;
            [current setValue:[NSNumber numberWithInt:number] forKey:@"syncedCount"];
            NSInteger of = [needingSyncCount intValue];
            [inv setTarget:self.delegate];
            [inv setSelector:@selector(syncQueueSynced:number:of:)];
            [inv setArgument:&o atIndex:2];
            [inv setArgument:&number atIndex:3];
            [inv setArgument:&of atIndex:4];
            [inv invoke];
        }
    }
    
    NSError *error = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
    
    if ([[current objectForKey:@"syncedCount"] intValue] >= needingSyncCount.intValue) {
        [self start];
    }
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    // was running into a bug in release build config where the object loader was 
    // getting deallocated after handling an error.  This is a kludge.
    self.loader = objectLoader;
    bool jsonParsingError = [error.domain isEqualToString:@"JKErrorDomain"] && error.code == -1;
    bool authFailure = [error.domain isEqualToString:@"NSURLErrorDomain"] && error.code == -1012;
    bool recordDeletedFromServer = (objectLoader.response.statusCode == 404 || objectLoader.response.statusCode == 410) &&
        objectLoader.method == RKRequestMethodPUT &&
        [objectLoader.sourceObject respondsToSelector:@selector(recordID)] &&
        [objectLoader.sourceObject performSelector:@selector(recordID)] != nil;
    
    if (jsonParsingError || authFailure) {
        [self stop];
        if ([self.delegate respondsToSelector:@selector(syncQueueAuthRequired)]) {
            [self.delegate performSelector:@selector(syncQueueAuthRequired)];
        }
    } else if (recordDeletedFromServer) {
        // if it was in the sync queue there were local changes, so post it again
        INatModel *record = (INatModel *)objectLoader.sourceObject;
        [record setSyncedAt:nil];
        [record setRecordID:nil];
        [record save];
    } else if ([self.delegate respondsToSelector:@selector(syncQueue:objectLoader:didFailWithError:)]) {
        NSMethodSignature *sig = [[self.delegate class]
                                  instanceMethodSignatureForSelector:@selector(syncQueue:objectLoader:didFailWithError:)];
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
        SyncQueue *sq = self;
        [inv setTarget:self.delegate];
        [inv setSelector:@selector(syncQueue:objectLoader:didFailWithError:)];
        [inv setArgument:&sq atIndex:2];
        [inv setArgument:&objectLoader atIndex:3];
        [inv setArgument:&error atIndex:4];
        [inv invoke];
    } else {
        [self stop];
    }
    
    // even if it was an error the object was still handled, so update the 
    // counter and move the queue forward if necessary
    [self next];
}

- (void)next
{
    NSMutableDictionary *current = self.queue.firstObject;
    if (!current) {
        [self stop];
        return;
    }
    
    NSNumber *needingSyncCount = [current objectForKey:@"needingSyncCount"];
    NSNumber *syncedCount = [current objectForKey:@"syncedCount"];
    [current setValue:[NSNumber numberWithInt:[syncedCount intValue] + 1]
               forKey:@"syncedCount"];
    if (self.isRunning && [[current objectForKey:@"syncedCount"] intValue] >= needingSyncCount.intValue) {
        [self start];
    }
}

- (void)objectLoaderDidLoadUnexpectedResponse:(RKObjectLoader *)objectLoader
{
    self.loader = objectLoader;
    [self stop];
    if ([self.delegate respondsToSelector:@selector(syncQueueUnexpectedResponse)]) {
        [self.delegate performSelector:@selector(syncQueueUnexpectedResponse)];
    }
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error
{
    if (request.method != RKRequestMethodDELETE) return;
    [self stop];
}

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response
{
    if (request.method != RKRequestMethodDELETE) return;
    if (!self.started) return;
    
    NSMutableDictionary *current = self.queue.firstObject;
    if (!current) {
        [self stop];
        return;
    }

    id model = [current objectForKey:@"model"];
    NSNumber *deletedRecordCount = [current objectForKey:@"deletedRecordCount"];
    [current setValue:[NSNumber numberWithInt:[deletedRecordCount intValue] - 1] 
               forKey:@"deletedRecordCount"];
    
    // if we're done deleting
    if ([[current objectForKey:@"deletedRecordCount"] intValue] <= 0) {
        // remove all deleted records
        NSArray *deletedRecords = [DeletedRecord objectsWithPredicate:
                                   [NSPredicate predicateWithFormat:
                                    @"modelName = %@", NSStringFromClass(model)]];
        for (DeletedRecord *dr in deletedRecords) {
            [dr deleteEntity];
        }
        NSError *error = nil;
        [[NSManagedObjectContext defaultContext] save:&error];
        
        // move the queue forward
        [self start];
    }
}

@end
