//
//  UploadObservationOperation.m
//  iNaturalist
//
//  Created by Alex Shepard on 6/19/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import "UploadObservationOperation.h"
#import "Observation.h"

@interface UploadObservationOperation ()
@property NSInteger totalBytesToUpload;
@property NSMutableDictionary *uploadedBytes;
@end

@implementation UploadObservationOperation

- (instancetype)init {
    if (self = [super init]) {
        self.totalBytesToUpload = 0;
        self.uploadedBytes = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)syncObservationFinishedSuccess:(BOOL)success syncError:(NSError *)syncError {
    // notify the delegate about the sync status
    dispatch_async(dispatch_get_main_queue(), ^{
        NSManagedObjectContext *context = [NSManagedObjectContext defaultContext];
        NSError *contextError = nil;
        Observation *o = [context existingObjectWithID:self.rootObjectId error:&contextError];
        if (o && success) {
            [self.delegate uploadManager:nil uploadSuccessFor:o];
        } else {
            NSError *error = nil;
            if (syncError) {
                error = syncError;
            } else if (contextError) {
                error = contextError;
            }
            [self.delegate uploadManager:nil uploadFailedFor:o error:error];
        }
    });
    
    // notify NSOperationQueue via KVO about operation status
    [self markOperationCompleted];
}

- (void)startUploadWork {
    
    if (!self.sessionManager) {
        [self syncObservationFinishedSuccess:NO syncError:nil];
        return;
    }
    
    NSManagedObjectContext *context = [NSManagedObjectContext defaultContext];
    NSError *contextError = nil;
    Observation *o = [context existingObjectWithID:self.rootObjectId error:&contextError];
    if (!o || contextError) {
        [self syncObservationFinishedSuccess:NO syncError:contextError];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate uploadManager:nil uploadStartedFor:o];
    });
    
    // figure out total bytes to upload
    self.totalBytesToUpload = 0;
    for (INatModel <Uploadable> *child in o.childrenNeedingUpload) {
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([child respondsToSelector:@selector(fileUploadParameter)]) {
            NSString *path = [child fileUploadParameter];
            NSDictionary *attrs = [fm attributesOfItemAtPath:path error:nil];
            self.totalBytesToUpload += [[attrs valueForKey:NSFileSize] integerValue];
        }
    }
    
    if (o.needsSync) {
        if (o.syncedAt) {
            [self putObservation:o];
        } else {
            [self postObservation:o];
        }
    } else if (o.childrenNeedingUpload.count > 0) {
        [self syncChildRecord:o.childrenNeedingUpload.firstObject
                ofObservation:o];
    } else {
        [self syncObservationFinishedSuccess:YES syncError:nil];
    }
}

- (void)postObservation:(Observation *)observation {
    [self syncObservation:observation method:@"POST"];
}

- (void)putObservation:(Observation *)observation {
    if (observation.childrenNeedingUpload.count > 0) {
        // first upload each of the children
        // when this is done, the last child callback will upload
        // the parent observation via PUT
        [self syncChildRecord:observation.childrenNeedingUpload.firstObject
                ofObservation:observation];
    } else {
        // just upload the parent via PUT
        [self syncObservation:observation method:@"PUT"];
    }
}
         
- (void)syncObservation:(Observation *)observation method:(NSString *)HTTPMethod {
    void (^successBlock)(NSURLSessionDataTask *, id _Nullable) = ^(NSURLSessionDataTask *task, id _Nullable responseObject) {
        // this observation has been synced
        observation.syncedAt = [NSDate date];
        
        // record ids come from the server
        if ([responseObject valueForKey:@"id"]) {
            observation.recordID = @([[responseObject valueForKey:@"id"] integerValue]);
        }
        
        // save the core data object store
        [[[RKObjectManager sharedManager] objectStore] save:nil];
        
        // if there are children to upload, upload first child
        if (observation.childrenNeedingUpload.count > 0) {
            [self syncChildRecord:observation.childrenNeedingUpload.firstObject
                    ofObservation:observation];
        } else {
            [self syncObservationFinishedSuccess:YES syncError:nil];
        }
    };
    
    void (^failureBlock)(NSURLSessionDataTask *, NSError *) = ^(NSURLSessionDataTask *task, NSError * _Nonnull error) {
        [self syncObservationFinishedSuccess:NO syncError:error];
    };
    
    if ([HTTPMethod isEqualToString:@"PUT"]) {
        NSString *path = [NSString stringWithFormat:@"/%@/%ld.json",
                          NSStringFromClass(observation.class).underscore.pluralize,
                          (long)observation.recordID.integerValue
                          ];
        [self.sessionManager PUT:path
                      parameters:[observation uploadableRepresentation]
                         success:successBlock
                         failure:failureBlock];
    } else {
        NSString *path = [NSString stringWithFormat:@"/%@.json",
                          NSStringFromClass(observation.class).underscore.pluralize];
        [self.sessionManager POST:path
                       parameters:[observation uploadableRepresentation]
                         progress:nil
                          success:successBlock
                          failure:failureBlock];
    }
}

- (void)syncChildRecord:(INatModel <Uploadable> *)child ofObservation:(Observation *)observation {
    NSString *HTTPMethod = child.syncedAt ? @"PUT" : @"POST";
    
    void (^successBlock)(NSURLSessionDataTask *, id _Nullable) = ^(NSURLSessionDataTask *task, id _Nullable responseObject) {
        // this observation has been synced
        child.syncedAt = [NSDate date];
        
        // record ids come from the server
        if ([responseObject valueForKey:@"id"]) {
            child.recordID = @([[responseObject valueForKey:@"id"] integerValue]);
        }
        
        // save the core data object store
        [[[RKObjectManager sharedManager] objectStore] save:nil];
        
        // if there are more children to upload, upload first child
        if (observation.childrenNeedingUpload.count > 0) {
            [self syncChildRecord:observation.childrenNeedingUpload.firstObject
                    ofObservation:observation];
        } else if (observation.needsSync && observation.syncedAt) {
            // if the observation still needs sync via PUT, do it now
            [self syncObservation:observation method:@"PUT"];
        } else {
            [self syncObservationFinishedSuccess:YES syncError:nil];
        }
    };
    
    void (^failureBlock)(NSURLSessionDataTask *, NSError *) = ^(NSURLSessionDataTask *task, NSError * _Nonnull error) {
        [self syncObservationFinishedSuccess:NO syncError:error];
    };
    
    void (^progressBlock)(NSProgress *) = ^(NSProgress * _Nonnull uploadProgress) {
        // update the local counter for this particular upload operation
        self.uploadedBytes[child.uuid] = @(uploadProgress.completedUnitCount);
        
        // notify the upload delegate about the total upload progress
        // for this observation
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate uploadManager:nil
                          uploadProgress:[self totalFileUploadProgress]
                                     for:observation];
        });
    };

    NSString *path = nil;
    if ([HTTPMethod isEqualToString:@"PUT"]) {
        path = [NSString stringWithFormat:@"/%@/%ld.json",
                NSStringFromClass(child.class).underscore.pluralize,
                (long)child.recordID.integerValue];
        
        [self.sessionManager PUT:path
                      parameters:[child uploadableRepresentation]
                         success:successBlock
                         failure:failureBlock];
    } else {
        path = [NSString stringWithFormat:@"/%@.json",
                NSStringFromClass(child.class).underscore.pluralize];
        
        if ([child respondsToSelector:@selector(fileUploadParameter)]) {
            // we'll need a body block for the multi-part post
            void (^bodyBlock)(id <AFMultipartFormData>) = ^(id<AFMultipartFormData>  _Nonnull formData) {
                NSString *path = [child fileUploadParameter];
                NSURL *fileUrl = [NSURL fileURLWithPath:path];
                [formData appendPartWithFileURL:fileUrl
                                           name:@"file"
                                       fileName:@"original.jpg"
                                       mimeType:@"image/jpeg"
                                          error:nil];
            };

            [self.sessionManager POST:path
                           parameters:[child uploadableRepresentation]
            constructingBodyWithBlock:bodyBlock
                             progress:progressBlock
                              success:successBlock
                              failure:failureBlock];
        } else {
            // skip the progress block if there was no file upload param
            [self.sessionManager POST:path
                           parameters:[child uploadableRepresentation]
                             progress:nil
                              success:successBlock
                              failure:failureBlock];
        }
    }
}

- (float)totalFileUploadProgress {
    if (self.totalBytesToUpload == 0) {
        return 0.0f;
    }
    
    NSInteger totalUploadedBytes = 0;
    for (NSNumber *completedBytes in [self.uploadedBytes allValues]) {
        totalUploadedBytes += completedBytes.integerValue;
    }
    return (float)totalUploadedBytes / self.totalBytesToUpload;
}


@end
