//
//  DeleteRecordOperation.m
//  iNaturalist
//
//  Created by Alex Shepard on 6/19/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import <RestKit/RestKit.h>

#import "DeleteRecordOperation.h"
#import "NSURL+INaturalist.h"
#import "DeletedRecord.h"

@implementation DeleteRecordOperation

- (void)deleteRecordFinishedSuccess:(BOOL)success syncError:(NSError *)syncError {
    // notify the delegate about the sync status
    dispatch_async(dispatch_get_main_queue(), ^{
        if (syncError) {
            NSManagedObjectContext *context = [NSManagedObjectContext defaultContext];
            NSError *contextError = nil;
            DeletedRecord *dr = [context existingObjectWithID:self.rootObjectId error:&contextError];
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
    
    if (!self.sessionManager) {
        [self markOperationCompleted];
        return;
    }
    
    NSManagedObjectContext *context = [NSManagedObjectContext defaultContext];
    NSError *contextError = nil;
    DeletedRecord *dr = [context existingObjectWithID:self.rootObjectId error:&contextError];
    if (!dr || contextError) {
        [self deleteRecordFinishedSuccess:NO syncError:contextError];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate deleteSessionStarted:dr];
    });

        
    NSString *deletePath = [NSString stringWithFormat:@"/%@/%ld",
                            dr.modelName.underscore.pluralize,
                            (long)dr.recordID.integerValue];
    NSString *urlString = [[NSURL URLWithString:deletePath
                                  relativeToURL:[NSURL inat_baseURL]] absoluteString];
    
    [self.sessionManager DELETE:urlString
                     parameters:nil
                        success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                            // purge from core data
                            [dr deleteEntity];
                            [[[RKObjectManager sharedManager] objectStore] save:nil];
                            
                            [self deleteRecordFinishedSuccess:YES syncError:nil];
                        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                            BOOL actualSuccess = NO;
                            NSHTTPURLResponse *r = [error.userInfo valueForKey:AFNetworkingOperationFailingURLResponseErrorKey];
                            if (r) {
                                if (r.statusCode == 404) {
                                    // purge from core data
                                    [dr deleteEntity];
                                    [[[RKObjectManager sharedManager] objectStore] save:nil];
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
