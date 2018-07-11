//
//  UploadObservationOperation.m
//  iNaturalist
//
//  Created by Alex Shepard on 6/19/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import "UploadObservationOperation.h"
#import "Observation.h"
#import "ProjectObservation.h"
#import "Project.h"
#import "ObservationFieldValue.h"
#import "Analytics.h"

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
            [self.delegate uploadSessionSuccessFor:o];
        } else {
            NSError *error = nil;
            if (syncError) {
                error = syncError;
            } else if (contextError) {
                error = contextError;
            }
            [self.delegate uploadSessionFailedFor:o error:error];
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
    
    // clear any validation errors
    o.validationErrorMsg = nil;
    // save the core data object store
    [[[RKObjectManager sharedManager] objectStore] save:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate uploadSessionStarted:o];
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
        NSString *httpMethod = o.syncedAt ? @"PUT" : @"POST";
        [self syncObservation:o method:httpMethod];
    } else if (o.childrenNeedingUpload.count > 0) {
        [self syncChildRecord:o.childrenNeedingUpload.firstObject
                ofObservation:o];
    } else {
        [self syncObservationFinishedSuccess:YES syncError:nil];
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
    
    NSDate *uploadStartTime = [NSDate date];
    
    void (^successBlock)(NSURLSessionDataTask *, id _Nullable) = ^(NSURLSessionDataTask *task, id _Nullable responseObject) {
        // this observation has been synced
        child.syncedAt = [NSDate date];
        
        // record ids come from the server
        if ([responseObject valueForKey:@"id"]) {
            child.recordID = @([[responseObject valueForKey:@"id"] integerValue]);
        }
        
        // save the core data object store
        [[[RKObjectManager sharedManager] objectStore] save:nil];
        
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
        // TODO: handle 422 validations for Project Observation Stuff
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

                if ([child isKindOfClass:ProjectObservation.class]) {
                    // add project validation error notice
                    ProjectObservation *po = (ProjectObservation *)child;
                    Observation *o = po.observation;
                    NSString *baseErrMsg = NSLocalizedString(@"Couldn't be added to project %@. %@",
                                                             @"Project validation error. first string is project title, second is the specific error");
                    o.validationErrorMsg = [NSString stringWithFormat:baseErrMsg,
                                            po.project.title, validationError];
                    // save the core data object store
                    [[[RKObjectManager sharedManager] objectStore] save:nil];
                    
                    // fall through to failing and reporting the error
                } else if ([child isKindOfClass:ObservationFieldValue.class]) {
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
            }
        }
        [self syncObservationFinishedSuccess:NO syncError:error];
    };
    
    void (^progressBlock)(NSProgress *) = ^(NSProgress * _Nonnull uploadProgress) {
        // update the local counter for this particular upload operation
        self.uploadedBytes[child.uuid] = @(uploadProgress.completedUnitCount);
        
        // notify the upload delegate about the total upload progress
        // for this observation
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate uploadSessionProgress:[self totalFileUploadProgress]
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
            // TODO: handle missing file for fileUploadParameter
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
