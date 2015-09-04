//
//  UploadManager.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/20/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "UploadManager.h"
#import "INatModel.h"
#import "DeletedRecord.h"
#import "Observation.h"
#import "Analytics.h"
#import "ObservationPhoto.h"
#import "ObservationFieldValue.h"
#import "ProjectObservation.h"
#import "INaturalistAppDelegate.h"

@interface UploadManager () <RKRequestDelegate, RKObjectLoaderDelegate> {
    Observation *_currentlyUploadingObservation;
    NSInteger _currentUploadSessionTotalObservations;
}

@property NSMutableArray *observationsToUpload;
@property NSMutableArray *recordsToDelete;
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
    
    // when deletes are finished, the last delete callback will start the first upload
    [self syncNextDelete];
}

- (void)cancelSyncsAndUploads {
    self.cancelled = YES;
    self.syncingDeletes = NO;
    self.uploading = NO;
    [[[RKObjectManager sharedManager] requestQueue] cancelRequestsWithDelegate:self];
    [self.delegate uploadCancelledFor:nil];
}

#pragma mark - private methods

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
        
        self.currentlyUploadingObservation = nextObservation;
        NSInteger idx = [self indexOfCurrentlyUploadingObservation] + 1;
        [self.delegate uploadStartedFor:nextObservation
                                 number:idx
                                     of:self.currentUploadSessionTotalObservations];
        //[self.delegate uploadStartedFor:nextObservation];
        [self uploadOneRecordForObservation:nextObservation];
    } else {
        // notify finished with uploading
        self.currentlyUploadingObservation = nil;
        self.uploading = NO;
        [self.delegate uploadSessionFinished];
    }
}

/**
 * Upload a record for an observation. If the observation itself needs
 * upload, then upload that first. If not, then work on the child records
 * that need upload.
 */
- (void)uploadOneRecordForObservation:(Observation *)observation {
    
    if (self.cancelled) {
        return;
    }

    if (!observation.needsUpload) {
        [self.delegate uploadSuccessFor:observation];
        self.currentlyUploadingObservation = nil;
        [self.observationsToUpload removeObject:observation];
        [self uploadNextObservation];
        return;
    }
    
    RKObjectLoaderBlock loaderBlock = nil;
    INatModel <Uploadable> *recordToUpload = nil;
    
    if (observation.needsSync) {
        // upload the observation itself
        loaderBlock = ^(RKObjectLoader *loader) {
            loader.objectMapping = [Observation mapping];
            loader.delegate = self;
        };
        recordToUpload = observation;
        
    } else {
        // upload a child record for the obs
        recordToUpload = [[observation childrenNeedingUpload] firstObject];
        
        if (!recordToUpload) {
            // notify finished with this observation
            [self.observationsToUpload removeObject:observation];
            [self uploadNextObservation];
            return;
        }
        
        loaderBlock = ^(RKObjectLoader *loader) {
            loader.objectMapping = [[recordToUpload class] mapping];
            loader.delegate = self;
            
            if ([recordToUpload respondsToSelector:@selector(fileUploadParameter)]) {
                NSString *path = [recordToUpload performSelector:@selector(fileUploadParameter)];
                
                if (!path) {
                    // the only case for now
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
                        
                        [self.delegate uploadFailedFor:recordToUpload error:error];
                        self.uploading = NO;
                        return;
                    }
                }
                
                INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
                RKObjectMapping* serializationMapping = [appDelegate.photoObjectManager.mappingProvider
                                                         serializationMappingForClass:[recordToUpload class]];
                NSError* error = nil;
                RKObjectSerializer *serializer = [RKObjectSerializer serializerWithObject:recordToUpload
                                                                                  mapping:serializationMapping];
                NSDictionary *dictionary = [serializer serializedObject:&error];
                
                // should really call completion with the error
                if (error) {
                    [self.delegate uploadFailedFor:recordToUpload error:error];
                    self.uploading = NO;
                    return;
                }
                
                RKParams* params = [RKParams paramsWithDictionary:dictionary];
                
                [params setFile:path
                       forParam:@"file"];
                loader.params = params;
            }
        };
    }
    
    if (recordToUpload && loaderBlock) {
        RKObjectManager *objectManager = [RKObjectManager sharedManager];
        
        if (recordToUpload.syncedAt) {
            [objectManager putObject:recordToUpload usingBlock:loaderBlock];
        } else {
            [objectManager postObject:recordToUpload usingBlock:loaderBlock];
        }
    } else {
        // notify finished with this observation
        [self.delegate uploadSuccessFor:observation];
        self.currentlyUploadingObservation = nil;
        [self.observationsToUpload removeObject:observation];
        [self uploadNextObservation];
        return;
    }
}




- (void)syncNextDelete {
    if (self.cancelled) {
        return;
    }
    
    if (self.recordsToDelete.count > 0) {
        // notify starting a new deletion
        DeletedRecord *nextDelete = [self.recordsToDelete firstObject];
        [self.delegate deleteStartedFor:nextDelete];
        
        NSString *nextDeletePath = [NSString stringWithFormat:@"/%@/%d",
                                    nextDelete.modelName.underscore.pluralize,
                                    nextDelete.recordID.intValue];
        
        [[RKClient sharedClient] delete:nextDeletePath
                             usingBlock:^(RKRequest *request) {
                                 request.delegate = self;
                                 request.onDidLoadResponse = ^(RKResponse *response) {
                                 };
                             }];
    } else {
        self.syncingDeletes = NO;
        // notify finished with deletions
        [self.delegate deleteSessionFinished];
        [self uploadNextObservation];
    }
}

#pragma mark - RKRequestDelegate
- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response {
    // check for 401 unauthorized
    if (response.statusCode == 401) {
        self.uploading = NO;
        [self.delegate uploadSessionAuthRequired];
        return;
    }

    if (request.method == RKRequestMethodDELETE) {
        DeletedRecord *thisDelete = [self.recordsToDelete firstObject];
        // update UI
        [self.delegate deleteSuccessFor:thisDelete];
        // debug log
        [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"SYNC deleted %@", thisDelete]];
        // update local work queue
        [self.recordsToDelete removeObject:thisDelete];
        // delete the backing local entity
        [thisDelete deleteEntity];
        // continue working on the work queue
        [self syncNextDelete];
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
    // if we've stopped uploading (ie due to an auth failure), ignore the object loader error
    if (!self.uploading) {
        return;
    }
    
    // notify about failure
    if (objectLoader.method == RKRequestMethodDELETE) {
        DeletedRecord *failedDelete = [self.recordsToDelete firstObject];
        [self.delegate deleteFailedFor:failedDelete error:error];
        self.uploading = NO;
    } else {
        // this masks all failures behind the observation failing to upload
        // is this the correct move?
        Observation *failedObservation = [self.observationsToUpload firstObject];
        [self.delegate uploadFailedFor:failedObservation error:error];
        self.uploading = NO;
    }
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObject:(INatModel *)object {
    NSError *error = nil;
    object.syncedAt = [NSDate date];

    [[[RKObjectManager sharedManager] objectStore] save:&error];
    if (error) {
        [self.delegate uploadFailedFor:object error:error];
    } else {
        if (self.cancelled) {
            [self.delegate uploadCancelledFor:object];
        } else {
            Observation *thisObservation = nil;
            if ([object isKindOfClass:[Observation class]]) {
                thisObservation = (Observation *)object;
            } else if ([object isKindOfClass:[ObservationPhoto class]]) {
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

- (void)dealloc {
    [[[RKObjectManager sharedManager] requestQueue] cancelRequestsWithDelegate:self];
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

@end
