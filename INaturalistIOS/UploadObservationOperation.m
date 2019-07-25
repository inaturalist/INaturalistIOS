//
//  UploadObservationOperation.m
//  iNaturalist
//
//  Created by Alex Shepard on 6/19/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import "UploadObservationOperation.h"
#import "Analytics.h"
#import "ExploreObservationRealm.h"
#import "ExploreProjectObservationRealm.h"
#import "ExploreProjectRealm.h"

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
        ExploreObservationRealm *o = [ExploreObservationRealm objectForPrimaryKey:self.uuid];
        if (o && success) {
            [self.delegate uploadSessionSuccessFor:o.uuid];
        } else {
            NSError *error = nil;
            if (syncError) {
                error = syncError;
            }
            [self.delegate uploadSessionFailedFor:o.uuid error:error];
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
    
    ExploreObservationRealm *o = [ExploreObservationRealm objectForPrimaryKey:self.uuid];
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
        [self.delegate uploadSessionStarted:self.uuid];
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
    
    if (o.needsSync) {
        NSString *httpMethod = o.syncedAt ? @"PUT" : @"POST";
        [self syncObservation:o method:httpMethod];
    } else if (o.childrenNeedingUpload.count > 0) {
        [self syncChildRecord:o.childrenNeedingUpload.firstObject
                ofObservation:o];
    } else {
        [self syncObservationFinishedSuccess:YES syncError:nil];
    }
}

- (void)syncObservation:(ExploreObservationRealm *)observation method:(NSString *)HTTPMethod {
    NSString *observationUUID = observation.uuid;
    
    void (^successBlock)(NSURLSessionDataTask *, id _Nullable) = ^(NSURLSessionDataTask *task, id _Nullable responseObject) {

        NSError *error = nil;
        MTLModel *result = [MTLJSONAdapter modelOfClass:ExploreObservation.class
                                     fromJSONDictionary:responseObject
                                                  error:&error];
        ExploreObservation *uploadedObs = (ExploreObservation *)result;

        // re-fetch, since we'll be on a callback thread
        ExploreObservationRealm *o = [ExploreObservationRealm objectForPrimaryKey:observationUUID];
        
        // update our local realm observation with server added fields
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        o.syncedAt = [NSDate date];
        o.observationId = uploadedObs.inatRecordId;
        [realm commitWriteTransaction];
        
        // if there are children to upload, upload first child
        if (o.childrenNeedingUpload.count > 0) {
            [self syncChildRecord:o.childrenNeedingUpload.firstObject
                    ofObservation:o];
        } else {
            [self syncObservationFinishedSuccess:YES syncError:nil];
        }
    };
    
    void (^failureBlock)(NSURLSessionDataTask *, NSError *) = ^(NSURLSessionDataTask *task, NSError * _Nonnull error) {
        [self syncObservationFinishedSuccess:NO syncError:error];
    };
    
    
    if ([HTTPMethod isEqualToString:@"PUT"]) {
        NSString *path = [NSString stringWithFormat:@"/v1/%@/%ld",
                          [observation.class endpointName],
                          (long)observation.inatRecordId
                          ];
        [self.nodeSessionManager PUT:path
                          parameters:[observation uploadableRepresentation]
                             success:successBlock
                             failure:failureBlock];
    } else {
        NSString *path = [NSString stringWithFormat:@"/v1/%@", [observation.class endpointName]];
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
    NSString *observationUUID = observation.uuid;
    NSString *childUUID = child.uuid;

    NSString *HTTPMethod = child.syncedAt ? @"PUT" : @"POST";
    
    NSDate *uploadStartTime = [NSDate date];
    
    void (^successBlock)(NSURLSessionDataTask *, id _Nullable) = ^(NSURLSessionDataTask *task, id _Nullable responseObject) {
        RLMRealm *realm = [RLMRealm defaultRealm];

        // this observation has been synced
        [realm beginWriteTransaction];
        child.syncedAt = [NSDate date];
        [realm commitWriteTransaction];
        
        // record ids come from the server
        if ([responseObject valueForKey:@"id"]) {
            [realm beginWriteTransaction];
            child.inatRecordId = [[responseObject valueForKey:@"id"] integerValue];
            [realm commitWriteTransaction];
        }
        
        if ([HTTPMethod isEqualToString:@"POST"] && [child respondsToSelector:@selector(fileUploadParameter)]) {
            // notify analytics about file upload performance
            NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:uploadStartTime];
            [[Analytics sharedClient] logMetric:@"PhotoUploadGauge" value:@(timeInterval)];
        }

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
                
                /*
                 TODO: realm
                if ([child isKindOfClass:ExploreProjectObservationRealm.class]) {
                    // add project validation error notice
                    ExploreProjectObservationRealm *po = (ExploreProjectObservationRealm *)child;
                    ExploreObservationRealm *o = po.observations.firstObject;
                    NSString *baseErrMsg = NSLocalizedString(@"Couldn't be added to project %@. %@",
                                                             @"Project validation error. first string is project title, second is the specific error");
                    RLMRealm *realm = [RLMRealm defaultRealm];
                    [realm beginWriteTransaction];
                    o.validationErrorMsg = [NSString stringWithFormat:baseErrMsg,
                                            po.project.title, validationError];
                    [realm commitWriteTransaction];
                    
                    // fall through to failing and reporting the error
                }
                if ([child isKindOfClass:ObservationFieldValue.class]) {
                    // add observation field validation error notice
                    ObservationFieldValue *po = (ObservationFieldValue *)child;
                    Observation *o = po.observation;
                    NSString *baseErrMsg = NSLocalizedString(@"Observation Field Validation error: %@",
                                                             @"Project validation error, with the specific error");
                    o.validationErrorMsg = [NSString stringWithFormat:baseErrMsg, validationError];
                    // save the core data object store
                    [[[RKObjectManager sharedManager] objectStore] save:nil];
                    
                    // fall through to failing and reporting the error
                }
                 */
            }
        }
        [self syncObservationFinishedSuccess:NO syncError:error];
    };
    
    void (^progressBlock)(NSProgress *) = ^(NSProgress * _Nonnull uploadProgress) {
        // update the local counter for this particular upload operation
        
        self.uploadedBytes[childUUID] = @(uploadProgress.completedUnitCount);
        
        // notify the upload delegate about the total upload progress
        // for this observation
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate uploadSessionProgress:[self totalFileUploadProgress]
                                             for:observationUUID];
        });
    };

    NSString *path = nil;
    if ([HTTPMethod isEqualToString:@"PUT"]) {
        path = [NSString stringWithFormat:@"/v1/%@/%ld",
                [child.class endpointName],
                (long)child.inatRecordId];
        
        [self.nodeSessionManager PUT:path
                          parameters:[child uploadableRepresentation]
                             success:successBlock
                             failure:failureBlock];
    } else {
        
        path = [NSString stringWithFormat:@"/v1/%@", [child.class endpointName]];
        
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
