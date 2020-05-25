//
//  UploadObservationOperation.m
//  iNaturalist
//
//  Created by Alex Shepard on 6/19/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>

#import "UploadObservationOperation.h"
#import "ExploreObservationRealm.h"
#import "ExploreProjectObservationRealm.h"
#import "ExploreObsFieldValueRealm.h"
#import "Analytics.h"
#import "Uploadable.h"

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
        ExploreObservationRealm *o = [ExploreObservationRealm objectForPrimaryKey:self.rootObjectUUID];
        // TODO: update uploader delegate for EOR/realm
        if (o) {
            [self.delegate uploadSessionSuccessFor:self.rootObjectUUID];
        } else {
            NSError *error = nil;
            if (syncError) {
                error = syncError;
            } else {
                // TODO: what happens here? can this reasonably happen?
            }
            [self.delegate uploadSessionFailedFor:self.rootObjectUUID error:error];
        }
    });
    
    // notify NSOperationQueue via KVO about operation status
    [self markOperationCompleted];
}

- (void)startUploadWork {
    
    if (!self.nodeSessionManager) {
        [self syncObservationFinishedSuccess:NO syncError:nil];
        return;
    }
    
    ExploreObservationRealm *o = [ExploreObservationRealm objectForPrimaryKey:self.rootObjectUUID];
    if (!o) {
        [self syncObservationFinishedSuccess:NO syncError:nil];
        return;
    }
    
    // clear any validation errors
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    o.validationErrorMsg = nil;
    [realm commitWriteTransaction];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate uploadSessionStarted:self.rootObjectUUID];
    });
    
    // figure out total bytes to upload
    self.totalBytesToUpload = 0;
    for (id <Uploadable> child in o.childrenNeedingUpload) {
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([child respondsToSelector:@selector(fileUploadParameter)]) {
            NSString *path = [child fileUploadParameter];
            NSDictionary *attrs = [fm attributesOfItemAtPath:path error:nil];
            self.totalBytesToUpload += [[attrs valueForKey:NSFileSize] integerValue];
        }
    }
    
    if (o.needsUpload) {
        NSString *httpMethod = o.timeSynced ? @"PUT" : @"POST";
        [self syncObservation:o method:httpMethod];
    } else if (o.childrenNeedingUpload.count > 0) {
        [self syncChildRecord:o.childrenNeedingUpload.firstObject
                ofObservation:o];
    } else {
        [self syncObservationFinishedSuccess:YES syncError:nil];
    }
}

- (void)syncObservation:(ExploreObservationRealm *)observation method:(NSString *)HTTPMethod {
    void (^successBlock)(NSURLSessionDataTask *, id _Nullable) = ^(NSURLSessionDataTask *task, id _Nullable responseObject) {
        // this observation has been synced
        ExploreObservationRealm *eor = [ExploreObservationRealm objectForPrimaryKey:self.rootObjectUUID];
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        eor.timeSynced = [NSDate date];
        [realm commitWriteTransaction];
        
        // record ids come from the server
        if ([responseObject valueForKey:@"id"]) {
            [realm beginWriteTransaction];
            eor.observationId = [[responseObject valueForKey:@"id"] integerValue];
            [realm commitWriteTransaction];
        }
                
        // if there are children to upload, upload first child
        if (eor.childrenNeedingUpload.count > 0) {
            [self syncChildRecord:eor.childrenNeedingUpload.firstObject
                    ofObservation:eor];
        } else {
            [self syncObservationFinishedSuccess:YES syncError:nil];
        }
    };
    
    void (^failureBlock)(NSURLSessionDataTask *, NSError *) = ^(NSURLSessionDataTask *task, NSError * _Nonnull error) {
        [self syncObservationFinishedSuccess:NO syncError:error];
    };
    
    
    if ([HTTPMethod isEqualToString:@"PUT"]) {
        NSString *path = [NSString stringWithFormat:@"/v1/%@/%ld",
                          [[observation class] endpointName],
                          (long)observation.observationId
                          ];
        [self.nodeSessionManager PUT:path
                          parameters:[observation uploadableRepresentation]
                             success:successBlock
                             failure:failureBlock];
    } else {
        NSString *path = [NSString stringWithFormat:@"/v1/%@",
                          [[observation class] endpointName]];
        if (self.userSiteId != 0) {
            path = [path stringByAppendingString:[NSString stringWithFormat:@"?inat_site_id=%ld",
                                                  (long)self.userSiteId]];
        }
        [self.nodeSessionManager POST:path
                           parameters:[observation uploadableRepresentation]
                             progress:nil
                              success:successBlock
                              failure:failureBlock];
    }
}

- (void)syncChildRecord:(id <Uploadable>)child ofObservation:(ExploreObservationRealm *)observation {
    NSString *HTTPMethod = child.timeSynced ? @"PUT" : @"POST";
    
    NSString *childUUID = [child uuid];
    NSDate *uploadStartTime = [NSDate date];
    
    void (^successBlock)(NSURLSessionDataTask *, id _Nullable) = ^(NSURLSessionDataTask *task, id _Nullable responseObject) {
        
        // refetch obs and child locally on this thread
        ExploreObservationRealm *eor = [ExploreObservationRealm objectForPrimaryKey:self.rootObjectUUID];
        id <Uploadable> localChild = nil;
        for (id <Uploadable>child in [eor childrenNeedingUpload]) {
            if ([child.uuid isEqualToString:childUUID]) {
                localChild = child;
            }
        }
        
        RLMRealm *realm = [RLMRealm defaultRealm];
        // this observation has been synced
        [realm beginWriteTransaction];
        localChild.timeSynced = [NSDate date];
        [realm commitWriteTransaction];
        
        // record ids come from the server
        if ([responseObject valueForKey:@"id"]) {
            [realm beginWriteTransaction];
            [localChild setRecordId:[[responseObject valueForKey:@"id"] integerValue]];
            [realm commitWriteTransaction];
        }
                
        if ([HTTPMethod isEqualToString:@"POST"] && [localChild respondsToSelector:@selector(fileUploadParameter)]) {
            // notify analytics about file upload performance
            NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:uploadStartTime];
            [[Analytics sharedClient] logMetric:@"PhotoUploadGauge" value:@(timeInterval)];
        }

        // if there are more children to upload, upload first child
        if (eor.childrenNeedingUpload.count > 0) {
            [self syncChildRecord:eor.childrenNeedingUpload.firstObject
                    ofObservation:eor];
        } else if (eor.needsUpload && eor.timeSynced) {
            // if the observation still needs sync via PUT, do it now
            [self syncObservation:eor method:@"PUT"];
        } else {
            [self syncObservationFinishedSuccess:YES syncError:nil];
        }
    };
    
    void (^failureBlock)(NSURLSessionDataTask *, NSError *) = ^(NSURLSessionDataTask *task, NSError * _Nonnull error) {
        // refetch obs and child locally on this thread
        ExploreObservationRealm *eor = [ExploreObservationRealm objectForPrimaryKey:self.rootObjectUUID];
        id <Uploadable> localChild = nil;
        for (id <Uploadable>child in [eor childrenNeedingUpload]) {
            if ([child.uuid isEqualToString:childUUID]) {
                localChild = child;
            }
        }

        if ([[error userInfo] valueForKey:AFNetworkingOperationFailingURLResponseErrorKey]) {
            NSHTTPURLResponse *response = [[error userInfo] valueForKey:AFNetworkingOperationFailingURLResponseErrorKey];
            if (response.statusCode == 422) {
                
                // try to extract a validation error from the json response
                NSData *data = [[error userInfo] valueForKey:AFNetworkingOperationFailingURLResponseDataErrorKey];
                NSError *jsonDecodeError = nil;
                id json = [NSJSONSerialization JSONObjectWithData:data
                                                          options:NSJSONReadingAllowFragments
                                                            error:&jsonDecodeError];
                
                NSString *validationError = error.localizedDescription;
                NSArray *validationErrors = [json valueForKey:@"errors"];
                if (validationErrors && validationErrors.count > 0) {
                    validationError = validationErrors.firstObject;
                }

                RLMRealm *realm = [RLMRealm defaultRealm];
                if ([localChild isKindOfClass:ExploreProjectObservationRealm.class]) {
                    // add project validation error notice
                    ExploreObservationRealm *eor = [ExploreObservationRealm objectForPrimaryKey:self.rootObjectUUID];
                    ExploreProjectObservationRealm *po = [ExploreProjectObservationRealm objectForPrimaryKey:childUUID];
                    NSString *baseErrMsg = NSLocalizedString(@"Couldn't be added to project %@. %@",
                                                             @"Project validation error. first string is project title, second is the specific error");
                    [realm beginWriteTransaction];
                    eor.validationErrorMsg = [NSString stringWithFormat:baseErrMsg,
                                              po.project.title, validationError];
                    [realm commitWriteTransaction];
                    
                    // fall through to failing and reporting the error
                } else if ([localChild isKindOfClass:ExploreObsFieldValueRealm.class]) {
                    // add observation field validation error notice
                    ExploreObservationRealm *eor = [ExploreObservationRealm objectForPrimaryKey:self.rootObjectUUID];
                    NSString *baseErrMsg = NSLocalizedString(@"Observation Field Validation error: %@",
                                                             @"Project validation error, with the specific error");
                    [realm beginWriteTransaction];
                    eor.validationErrorMsg = [NSString stringWithFormat:baseErrMsg, validationError];
                    [realm commitWriteTransaction];
                    
                    // fall through to failing and reporting the error
                }
            }
        }
        [self syncObservationFinishedSuccess:NO syncError:error];
    };
    
    void (^progressBlock)(NSProgress *) = ^(NSProgress * _Nonnull uploadProgress) {
        // silently do nothing if we can't fetch a UUID for a child
        // this shouldn't happen but also shouldn't crash the app
        if (!childUUID) { return; }
        
        // update the local counter for this particular upload operation
        self.uploadedBytes[childUUID] = @(uploadProgress.completedUnitCount);
        
        // notify the upload delegate about the total upload progress
        // for this observation
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate uploadSessionProgress:[self totalFileUploadProgress]
                                             for:self.rootObjectUUID];
        });
    };

    NSString *path = nil;
    if ([HTTPMethod isEqualToString:@"PUT"]) {
        path = [NSString stringWithFormat:@"/v1/%@/%ld",
                [[child class] endpointName],
                (long)[child recordId]];
        
        [self.nodeSessionManager PUT:path
                          parameters:[child uploadableRepresentation]
                             success:successBlock
                             failure:failureBlock];
    } else {
        path = [NSString stringWithFormat:@"/v1/%@", [[child class] endpointName]];
        
        if ([child respondsToSelector:@selector(fileUploadParameter)]) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:[child fileUploadParameter]]) {
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
                
                [self.nodeSessionManager POST:path
                                   parameters:[child uploadableRepresentation]
                    constructingBodyWithBlock:bodyBlock
                                     progress:progressBlock
                                      success:successBlock
                                      failure:failureBlock];
            } else {
                // fast fail - we need a file but it doesn't exist
                [self syncObservationFinishedSuccess:NO syncError:nil];
            }
        } else {
            // skip the progress block if there was no file upload param
            [self.nodeSessionManager POST:path
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
