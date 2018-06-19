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

@interface UploadManager () <RKRequestDelegate, RKObjectLoaderDelegate> {
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
@end

@implementation UploadManager

#pragma mark - public methods

/**
 * Public method that serially uploads a list of observations.
 */
- (void)uploadObservations:(NSArray *)observations {
    self.uploading = YES;
    self.cancelled = NO;
    
    self.observationsToUpload = [observations mutableCopy];
    _currentUploadSessionTotalObservations = self.observationsToUpload.count;
    
    self.sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL inat_baseURL]];
    [self.sessionManager.requestSerializer setValue:[[NSUserDefaults standardUserDefaults] stringForKey:INatTokenPrefKey]
                                 forHTTPHeaderField:@"Authorization"];
    
    [self uploadNextObservation];
}

/**
 * Public method that serially syncs/uploads a list of deleted records,
 * then uploads a list of new or updated observations.
 */
- (void)syncDeletedRecords:(NSArray *)deletedRecords thenUploadObservations:(NSArray *)recordsToUpload {
    
    self.uploading = YES;
    self.syncingDeletes = YES;
    self.cancelled = NO;
    
    
    
    self.recordsToDelete = [deletedRecords mutableCopy];
    
    self.observationsToUpload = [recordsToUpload mutableCopy];
    _currentUploadSessionTotalObservations = self.observationsToUpload.count;
    
    self.sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL inat_baseURL]];
    [self.sessionManager.requestSerializer setValue:[[NSUserDefaults standardUserDefaults] stringForKey:INatTokenPrefKey]
                                 forHTTPHeaderField:@"Authorization"];
    
    // when deletes are finished, the last delete callback will start the first upload
    [self syncNextDelete];
}

- (void)cancelSyncsAndUploads {
    // can't cancel if we're not actually doing anything
    if (!self.syncingDeletes && !self.isUploading) { return; }
    
    self.cancelled = YES;
    self.syncingDeletes = NO;
    self.uploading = NO;
    [[[RKObjectManager sharedManager] requestQueue] cancelRequestsWithDelegate:self];
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

/**
 * Upload the next observation in our list of observations.
 *
 * If the list is empty, we're finished, so notify the delegate and cleanup.
 */
- (void)uploadNextObservation {
    
    if (self.cancelled) {
        return;
    }

    if (self.observationsToUpload.count > 0) {
        // notify starting a new observation
        Observation *nextObservation = [self.observationsToUpload firstObject];
        // clear any previous validation errors
        nextObservation.validationErrorMsg = nil;
        self.currentlyUploadingObservation = nextObservation;
        NSInteger idx = [self indexOfCurrentlyUploadingObservation] + 1;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate uploadManager:self
                        uploadStartedFor:nextObservation
                                  number:idx
                                      of:self.currentUploadSessionTotalObservations];
        });
        if (nextObservation.syncedAt) {
            // need to PUT it and its children
        } else {
            // need to POST it
            [self postNewObservation:nextObservation];
        }
    } else {
        [self stopUploadActivity];

        // notify finished with uploading
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate uploadManagerUploadSessionFinished:self];
        });
    }
}

- (void)postRecord:(INatModel <Uploadable> *)record associatedObservation:(Observation *)observation {
    NSString *path = [NSString stringWithFormat:@"/%@.json",
                      NSStringFromClass(record.class).underscore.pluralize];
    
    void (^successBlock)(NSURLSessionDataTask *, id _Nullable) = ^(NSURLSessionDataTask *task, id _Nullable responseObject) {
        record.syncedAt = [NSDate date];
        if ([responseObject valueForKey:@"id"]) {
            record.recordID = @([[responseObject valueForKey:@"id"] integerValue]);
        }
        
        NSError *syncError = nil;
        [[[RKObjectManager sharedManager] objectStore] save:&syncError];
        if (syncError) {
            [self stopUploadActivity];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate uploadManager:self
                             uploadFailedFor:observation
                                       error:syncError];
            });
        } else {
            INatModel <Uploadable> *nextChild = [[observation childrenNeedingUpload] firstObject];
            if (nextChild) {
                [self postRecord:nextChild associatedObservation:observation];
            } else {
                [self.delegate uploadManager:self uploadSuccessFor:observation];
                [self.observationsToUpload removeObject:observation];
                [self uploadNextObservation];
            }
        }
    };
    
    void (^failureBlock)(NSURLSessionDataTask *, NSError *) = ^(NSURLSessionDataTask *task, NSError * _Nonnull error) {
        NSLog(@"failure");
    };
    
    void (^bodyBlock)(id <AFMultipartFormData>) = ^(id<AFMultipartFormData>  _Nonnull formData) {
        NSString *path = [record fileUploadParameter];
        NSURL *fileUrl = [NSURL fileURLWithPath:path];
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
        NSLog(@"file size is %lld", [[attrs valueForKey:NSFileSize] longLongValue]);
        [formData appendPartWithFileURL:fileUrl
                                   name:@"file"
                               fileName:@"original.jpg"
                               mimeType:@"image/jpeg"
                                  error:nil];
    };
    
    void (^progressBlock)(NSProgress *) = ^(NSProgress * _Nonnull uploadProgress) {
        
        [self.uploadTasksProgress setObject:@(uploadProgress.completedUnitCount) forKey:[record uuid]];
        
        NSInteger totalDone = 0;
        for (NSNumber *completedUnitCount in self.uploadTasksProgress.allValues) {
            totalDone += [completedUnitCount integerValue];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate uploadManager:self
                          uploadProgress:(float)totalDone / self.currentSessionTotalToUpload
                                     for:observation];
        });
    };
    
    if ([record respondsToSelector:@selector(fileUploadParameter)]) {
        // multipart form post
        [self.sessionManager POST:path
                       parameters:[record uploadableRepresentation]
        constructingBodyWithBlock:bodyBlock
                         progress:progressBlock
                          success:successBlock
                          failure:failureBlock];
    } else {
        // regular post
        [self.sessionManager POST:path
                       parameters:[record uploadableRepresentation]
                         progress:progressBlock
                          success:successBlock
                          failure:failureBlock];
    }
}

- (void)postNewObservation:(Observation *)observation {
    
    // calculate total file size to upload
    self.currentSessionTotalToUpload = 0.0f;
    self.currentSessionTotalUploaded = 0.0f;
    for (INatModel <Uploadable> *child in [observation childrenNeedingUpload]) {
        if ([child respondsToSelector:@selector(fileUploadParameter)]) {
            NSString *path = [child fileUploadParameter];
            NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
            self.currentSessionTotalToUpload += [[attrs valueForKey:NSFileSize] longLongValue];
        }
    }
    [self.uploadTasksProgress removeAllObjects];
    
    [self postRecord:observation associatedObservation:observation];
    return;
    //[self uploadRecord:observation associatedObservation:observation method:@"POST"];
    
    NSString *path = [NSString stringWithFormat:@"/%@.json",
                      NSStringFromClass(observation.class).underscore.pluralize];
    
    [self.sessionManager POST:path parameters:[observation uploadableRepresentation] progress:^(NSProgress * _Nonnull uploadProgress) {
        
        NSLog(@"got progress %f", uploadProgress.fractionCompleted);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"success: %@", responseObject);
        
        for (INatModel <Uploadable> *child in observation.childrenNeedingUpload) {
            NSString *path = [NSString stringWithFormat:@"/%@.json",
                              NSStringFromClass(child.class).underscore.pluralize];
            
            if ([child respondsToSelector:@selector(fileUploadParameter)]) {
                
                [self.sessionManager POST:path parameters:[child uploadableRepresentation] constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                    NSString *path = [child fileUploadParameter];
                    NSURL *fileUrl = [NSURL fileURLWithPath:path];
                    [formData appendPartWithFileURL:fileUrl
                                               name:@"file"
                                           fileName:@"original.jpg"
                                           mimeType:@"image/jpeg"
                                              error:nil];
                } progress:^(NSProgress * _Nonnull uploadProgress) {
                    NSLog(@"got progress in child %f", uploadProgress.fractionCompleted);
                } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    NSLog(@"success in child %@", responseObject);
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    NSLog(@"failure in child, %@", error);
                }];
                
            } else {
                [self.sessionManager POST:path parameters:[child uploadableRepresentation]
                                 progress:^(NSProgress * _Nonnull uploadProgress) {
                                     NSLog(@"progress in child %f", uploadProgress.fractionCompleted);
                                 } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                     NSLog(@"success in child %@", responseObject);
                                 } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                     NSLog(@"failure in child %@", error);
                                 }];
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"failure: %@", error);
    }];
}

/*
- (void)multipartPostChild:(INatModel <Uploadable> *)child ofObservation:(Observation *)observation {
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL inat_baseURL]];

    if ([child isKindOfClass:[ObservationPhoto class]]) {
        NSString *uuid = nil;
        if ([child respondsToSelector:@selector(uuid)]) {
            uuid = (NSString *)[child performSelector:@selector(uuid)];
        }
        if (uuid) {
            // for older observations, uuids could have been uppercase
            // or lowercase depending on where they originated.
            self.startTimesForPhotoUploads[[uuid lowercaseString]] = [NSDate date];
        }
    }
    
    NSString *nextUploadPath = [NSString stringWithFormat:@"/%@.json",
                                NSStringFromClass(child.class).underscore.pluralize];
    NSString *urlString = [[NSURL URLWithString:nextUploadPath
                                  relativeToURL:[NSURL inat_baseURL]] absoluteString];
    
    NSDictionary *params = [child uploadableRepresentation];
    NSMutableURLRequest *request = nil;
    
    NSError *uploadConstructionError = nil;
    // upload as multipart post
    NSString *path = [child fileUploadParameter];
    
    // TODO: handle no path
    if (!path) {
        if ([recordToUpload isKindOfClass:[ObservationPhoto class]]) {
            // if there's no file for this photo, bail on it and the upload process
            ObservationPhoto *op = (ObservationPhoto *)recordToUpload;
            
            // human readable index
            NSUInteger index = [op.observation.sortedObservationPhotos indexOfObject:op] + 1;
            NSString *obsName;
            if (op.observation.speciesGuess && ![op.observation.speciesGuess isEqualToString:@""])
                obsName = op.observation.speciesGuess;
            else
                obsName = NSLocalizedString(@"Something", @"Name of an observation when we don't have a species guess.");
            
            NSString *errorMsg = [NSString stringWithFormat:NSLocalizedString(@"Failed to upload photo # %d from observation '%@'",
                                                                              @"error message when an obs photo doesn't have a file on the phone."),
                                  index, obsName];
            NSError *error = [NSError errorWithDomain:@"org.inaturalist"
                                                 code:1201
                                             userInfo:@{
                                                        NSLocalizedDescriptionKey: errorMsg,
                                                        }];
            [op destroy];
            
            [self stopUploadActivity];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate uploadManager:self uploadFailedFor:recordToUpload error:error];
            });
            
            return;
        }
    }
    
    
    NSURL *fileUrl = [NSURL fileURLWithPath:path];
    request = [[manager.requestSerializer multipartFormRequestWithMethod:@"POST"
                                                               URLString:urlString
                                                              parameters:params
                                               constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                                                   [formData appendPartWithFileURL:fileUrl
                                                                              name:@"file"
                                                                          fileName:@"original.jpg"
                                                                          mimeType:@"image/jpeg"
                                                                             error:nil];
                                               }
                                                                   error:&uploadConstructionError] mutableCopy];
    
    if (uploadConstructionError) {
        [self.delegate uploadManager:self uploadFailedFor:observation error:uploadConstructionError];
        // TODO: what to do here?
        return;
    }
    [request addValue:[[NSUserDefaults standardUserDefaults] stringForKey:INatTokenPrefKey]
   forHTTPHeaderField:@"Authorization"];
    
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        child.syncedAt = [NSDate date];
        if ([responseObject valueForKey:@"id"]) {
            child.recordID = @([[responseObject valueForKey:@"id"] integerValue]);
        }
        
        NSError *syncError = nil;
        [[[RKObjectManager sharedManager] objectStore] save:&syncError];
        if (syncError) {
            [self stopUploadActivity];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate uploadManager:self
                             uploadFailedFor:observation
                                       error:syncError];
            });
        } else {
            [self uploadOneRecordForObservation:observation];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        NSLog(@"upload failed %@", error);
        
    }];
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        float progress = ((float)totalBytesWritten) / totalBytesExpectedToWrite;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate uploadManager:self uploadProgress:progress for:observation];
        });
    }];
    
    [manager.operationQueue addOperation:operation];
}
     */

/*
- (void)uploadRecord:(INatModel <Uploadable> *)record associatedObservation:(Observation *)observation method:(NSString *)httpMethod {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager alloc] initWithBaseURL:[NSURL inat_baseURL];
    
    //AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL inat_baseURL]];
    
    NSString *uploadPath = nil;
    if ([httpMethod isEqualToString:@"POST"]) {
        uploadPath = [NSString stringWithFormat:@"/%@.json",
                      NSStringFromClass(record.class).underscore.pluralize];
    } else {
        uploadPath = [NSString stringWithFormat:@"/%@/%ld.json",
                      NSStringFromClass(record.class).underscore.pluralize,
                      (long)record.recordID.integerValue];
    }
    NSString *urlString = [[NSURL URLWithString:uploadPath
                                  relativeToURL:[NSURL inat_baseURL]] absoluteString];
    
    NSDictionary *params = [record uploadableRepresentation];
    NSMutableURLRequest *request = nil;
    
    NSError *uploadConstructionError = nil;
    // upload as just a post/put
    request = [[manager.requestSerializer requestWithMethod:httpMethod
                                                  URLString:urlString
                                                 parameters:params
                                                      error:&uploadConstructionError] mutableCopy];
    
    if (uploadConstructionError) {
        [self.delegate uploadManager:self uploadFailedFor:observation error:uploadConstructionError];
        // TODO: what to do here?
        return;
    }
    [request addValue:[[NSUserDefaults standardUserDefaults] stringForKey:INatTokenPrefKey]
   forHTTPHeaderField:@"Authorization"];
    
    
    
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        record.syncedAt = [NSDate date];
        if ([responseObject valueForKey:@"id"]) {
            record.recordID = @([[responseObject valueForKey:@"id"] integerValue]);
        }
        
        NSError *syncError = nil;
        [[[RKObjectManager sharedManager] objectStore] save:&syncError];
        if (syncError) {
            [self stopUploadActivity];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate uploadManager:self
                             uploadFailedFor:observation
                                       error:syncError];
            });
        } else {
            [self uploadOneRecordForObservation:observation];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // TODO: handle this
        NSLog(@"upload failed %@", error);
        
    }];
    
    [manager.operationQueue addOperation:operation];
}
 */

/**
 * Upload a record for an observation. If the observation itself needs
 * upload, then upload that first. If not, then work on the child records
 * that need upload.
 */
- (void)uploadOneRecordForObservation:(Observation *)observation {
    /*
    if (self.cancelled) {
        return;
    }

    if ((!observation.needsUpload && observation.childrenNeedingUpload.count == 0) || !observation.uuid) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate uploadManager:self uploadSuccessFor:observation];
        });
        self.currentlyUploadingObservation = nil;
        [self.observationsToUpload removeObject:observation];
        [self uploadNextObservation];
        return;
    }
    
    if (observation.needsSync && !observation.syncedAt) {
        [self postNewObservation:observation];
    } else if ([[observation childrenNeedingUpload] count] > 0) {
        // if the observation needs to put PUT, do it after the
        // children have been sent.
        
        // upload a child record for the obs
        INatModel <Uploadable> *child = [[observation childrenNeedingUpload] firstObject];
        
        if (!child) {
            // notify finished with this observation
            [self.observationsToUpload removeObject:observation];
            [self uploadNextObservation];
            return;
        }
        
        if ([child respondsToSelector:@selector(fileUploadParameter)]) {
            [self multipartPostChild:child ofObservation:observation];
        } else if (child.syncedAt) {
            [self putChild:child ofObservation:observation];
        } else {
            [self postChild:child ofObservation:observation];
        }
    } else if (observation.needsSync) {
        [self putObservation:observation];
    } else {
        // notify finished with this observation
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate uploadManager:self uploadSuccessFor:observation];
        });
        self.currentlyUploadingObservation = nil;
        [self.observationsToUpload removeObject:observation];
        [self uploadNextObservation];
        return;
    }
     */
}




- (void)syncNextDelete {
    if (self.cancelled) {
        return;
    }
    
    if (self.recordsToDelete.count > 0) {
        // notify starting a new deletion
        DeletedRecord *nextDelete = [self.recordsToDelete firstObject];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate uploadManager:self deleteStartedFor:nextDelete];
        });
        
        NSString *nextDeletePath = [NSString stringWithFormat:@"/%@/%d",
                                    nextDelete.modelName.underscore.pluralize,
                                    nextDelete.recordID.intValue];
        NSString *urlString = [[NSURL URLWithString:nextDeletePath
                                      relativeToURL:[NSURL inat_baseURL]] absoluteString];
        
        [self.sessionManager DELETE:urlString parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            // update UI
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate uploadManager:self deleteSuccessFor:nextDelete];
            });
            
            // debug log
            [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"SYNC deleted %@", nextDelete]];
            
            // update local work queue
            [self.recordsToDelete removeObject:nextDelete];
            
            // delete the backing local entity
            [nextDelete deleteEntity];
            
            // continue working on the work queue
            [self syncNextDelete];
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)task.response;
            if (httpResponse.statusCode == 404) {
                // already deleted remotely, just keep going
                
                // update UI
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate uploadManager:self deleteSuccessFor:nextDelete];
                });
                
                // debug log
                [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"SYNC deleted %@", nextDelete]];
                
                // update local work queue
                [self.recordsToDelete removeObject:nextDelete];
                
                // delete the backing local entity
                [nextDelete deleteEntity];
                
                // continue working on the work queue
                [self syncNextDelete];
            } else {
                [self stopUploadActivity];
                
                // debug log
                [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"SYNC delete failed %@", nextDelete]];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate uploadManagerSessionFailed:self errorCode:httpResponse.statusCode];
                });
            }
            
        }];
        
        [[Analytics sharedClient] debugLog:@"Network - Delete One Record During Upload"];
    } else {
        self.syncingDeletes = NO;
        // notify finished with deletions
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate uploadManagerDeleteSessionFinished:self];
        });
        
        // start uploads
        [self uploadNextObservation];
    }
}

- (void)stopUploadActivity {
    self.uploading = NO;
    self.syncingDeletes = NO;
    self.currentlyUploadingObservation = nil;
    
    [self.sessionManager invalidateSessionCancelingTasks:YES];
}

#pragma mark - RKRequestDelegate

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response {
    // check for 401 unauthorized and 403 forbidden
    if (response.statusCode == 401 || response.statusCode == 403) {
        [self stopUploadActivity];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate uploadManagerSessionFailed:self errorCode:response.statusCode];
        });
        return;
    }
    
    if (request.method == RKRequestMethodDELETE) {
    } else {
        Observation *thisUpload = [self.observationsToUpload firstObject];
        INatModel *record = thisUpload.needsSync ? thisUpload : [thisUpload.childrenNeedingUpload firstObject];
        if (record) {
            bool recordDeletedFromServer = (response.statusCode == 404 || response.statusCode == 410)
            && request.method == RKRequestMethodPUT
            && [record respondsToSelector:@selector(recordID)]
            && [record performSelector:@selector(recordID)] != nil;
            
            if (recordDeletedFromServer) {
                // if it was in the sync queue there were local changes, so post it again
                [record setSyncedAt:nil];
                [record setRecordID:nil];
                [record save];
            }
        }
    }
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    
    if ([objectLoader.sourceObject isKindOfClass:ProjectObservation.class] && objectLoader.response.statusCode == 422) {
        // server returns this code when the project validation fails
        // this is a non-fatal error - start working on the next observation.
        [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"Upload - Project Observation Error %@",
                                            error.localizedDescription]];
        
        // mark this observation as needing validation
        ProjectObservation *po = (ProjectObservation *)objectLoader.sourceObject;
        Observation *o = po.observation;
        NSString *baseErrMsg = NSLocalizedString(@"Couldn't be added to project %@. %@",
                                                 @"Project validation error. first string is project title, second is the specific error");
        o.validationErrorMsg = [NSString stringWithFormat:baseErrMsg, po.project.title, error.localizedDescription];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate uploadManager:self nonFatalErrorForObservation:o];
        });
        
        // continue uploading other observations
        self.currentlyUploadingObservation = nil;
        [self.observationsToUpload removeObject:o];
        [self uploadNextObservation];
        
        return;
    }
    
    if ([objectLoader.sourceObject isKindOfClass:ObservationFieldValue.class]) {
        
        [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"Upload - Observation Field Value Error %@",
                                            error.localizedDescription]];
        
        // HACK: not sure where these observationless OFVs are coming from, so I'm just deleting
        // them and hoping for the best. I did add some Flurry logging for ofv creation, though.
        // kueda 20140112
        ObservationFieldValue *ofv = (ObservationFieldValue *)objectLoader.sourceObject;
        if (!ofv.observation) {
            NSLog(@"ERROR: deleted mysterious ofv: %@", ofv);
            [ofv deleteEntity];
            
            // continue uploading
            [self uploadOneRecordForObservation:ofv.observation];
            
            return;
        }
    }
    
    [self stopUploadActivity];
    
    NSError *reportingError = nil;
    NSError *parseError = nil;
    NSDictionary *body = [objectLoader.response parsedBody:&parseError];
    if (!parseError && body && [body valueForKey:@"error"]) {
        NSDictionary *info = @{NSLocalizedDescriptionKey: [body valueForKey:@"error"] };
        reportingError = [NSError errorWithDomain:@"org.inaturalist.ios" code:objectLoader.response.statusCode userInfo:info];
    } else {
        reportingError = error;
    }
    
    Observation *failedObservation = [self.observationsToUpload firstObject];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate uploadManager:self uploadFailedFor:failedObservation error:reportingError];
    });
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObject:(INatModel *)object {
    NSString *uuid = nil;
    if ([object respondsToSelector:@selector(uuid)]) {
        uuid = (NSString *)[object performSelector:@selector(uuid)];
    }
    
    // for older observations, uuids could have been uppercase
    // or lowercase depending on where they originated.
    if (uuid && [self.startTimesForPhotoUploads objectForKey:[uuid lowercaseString]]) {
        NSDate *startTime = self.startTimesForPhotoUploads[[uuid lowercaseString]];
        NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:startTime];
        
        [[Analytics sharedClient] logMetric:@"PhotoUploadGauge" value:@(timeInterval)];
    }
    
    NSError *error = nil;
    object.syncedAt = [NSDate date];
    
    [[[RKObjectManager sharedManager] objectStore] save:&error];
    if (error) {
        [self stopUploadActivity];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate uploadManager:self uploadFailedFor:object error:error];
        });
    } else {
        if (self.cancelled) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate uploadManager:self cancelledFor:object];
            });
        } else {
            Observation *thisObservation = nil;
            if ([object isKindOfClass:[Observation class]]) {
                thisObservation = (Observation *)object;
            } else if ([object isKindOfClass:[ObservationPhoto class]]) {
                ObservationPhoto *op = (ObservationPhoto *)object;
                [[ImageStore sharedImageStore] makeExpiring:op.photoKey];
                thisObservation = ((ObservationPhoto *)object).observation;
            } else if ([object isKindOfClass:[ProjectObservation class]]) {
                thisObservation = ((ProjectObservation *)object).observation;
            } else if ([object isKindOfClass:[ObservationFieldValue class]]) {
                thisObservation = ((ObservationFieldValue *)object).observation;
            }
            if (thisObservation) {
                [self uploadOneRecordForObservation:thisObservation];
            }
        }
    }
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
        
        self.startTimesForPhotoUploads = [[NSMutableDictionary alloc] init];
        self.photoUploads = [[NSMutableDictionary alloc] init];
        
        self.sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL inat_baseURL]];
        [self.sessionManager.requestSerializer setValue:[[NSUserDefaults standardUserDefaults] stringForKey:INatTokenPrefKey]
                                     forHTTPHeaderField:@"Authorization"];
        
        self.uploadTasksProgress = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.sessionManager invalidateSessionCancelingTasks:YES];
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
    return [self.reachabilityObserver isNetworkReachable];
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

@end
