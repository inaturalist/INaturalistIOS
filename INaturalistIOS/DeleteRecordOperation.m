//
//  DeleteRecordOperation.m
//  iNaturalist
//
//  Created by Alex Shepard on 6/19/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import "DeleteRecordOperation.h"
#import "NSURL+INaturalist.h"
#import "ExploreDeletedRecord.h"

@implementation DeleteRecordOperation

- (void)deleteRecordFinishedSuccess:(BOOL)success syncError:(NSError *)syncError {
    // notify the delegate about the sync status
    dispatch_async(dispatch_get_main_queue(), ^{
        if (syncError) {
            ExploreDeletedRecord *dr = [ExploreDeletedRecord deletedRecordId:self.recordId withModelName:self.modelName];
            [self.delegate deleteSessionFailedFor:dr error:syncError];
        }
    });
    
    // notify NSOperationQueue via KVO about operation status
    [super markOperationCompleted];
}

- (void)startUploadWork {
    if (self.cancelled) {
        [self markOperationCompleted];
        return;
    }
    
    if (!self.nodeSessionManager) {
        [self markOperationCompleted];
        return;
    }
    
    ExploreDeletedRecord *dr = [ExploreDeletedRecord deletedRecordId:self.recordId withModelName:self.modelName];

    if (!dr) {
        [self deleteRecordFinishedSuccess:NO syncError:nil];
        return;
    }
    
    if (![dr isKindOfClass:[ExploreDeletedRecord class]]) {
        [self markOperationCompleted];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate deleteSessionStarted:dr];
    });
    
    NSString *deletePath = [NSString stringWithFormat:@"/v1/%@/%ld", self.endpointName, (long)self.recordId];
    
    [self.nodeSessionManager DELETE:deletePath
                         parameters:nil
                            success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                // mark as synced
                                ExploreDeletedRecord *dr = [ExploreDeletedRecord deletedRecordId:self.recordId withModelName:self.modelName];
                                RLMRealm *realm = [RLMRealm defaultRealm];
                                [realm beginWriteTransaction];
                                dr.synced = YES;
                                [realm commitWriteTransaction];
                                
                                [self deleteRecordFinishedSuccess:YES syncError:nil];
                            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                BOOL actualSuccess = NO;
                                NSHTTPURLResponse *r = [error.userInfo valueForKey:AFNetworkingOperationFailingURLResponseErrorKey];
                                if (r) {
                                    if (r.statusCode == 404 || r.statusCode == 403) {
                                        // treat 404s and 403s as successful deletions
                                        // 404 means it was already deleted
                                        // 403 means you don't own the resource and can't delete it
                                        // in either case don't block the user from doing other stuff
                                        ExploreDeletedRecord *dr = [ExploreDeletedRecord deletedRecordId:self.recordId withModelName:self.modelName];
                                        RLMRealm *realm = [RLMRealm defaultRealm];
                                        [realm beginWriteTransaction];
                                        dr.synced = YES;
                                        [realm commitWriteTransaction];

                                        actualSuccess = YES;
                                    }
                                }
                                
                                if (actualSuccess) {
                                    [self deleteRecordFinishedSuccess:YES syncError:nil];
                                } else {
                                    [self deleteRecordFinishedSuccess:NO syncError:error];
                                }
                            }];
}

@end
