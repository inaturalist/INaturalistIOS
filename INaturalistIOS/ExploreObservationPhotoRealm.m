//
//  ExploreObservationPhotoRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/2/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import "ExploreObservationPhotoRealm.h"
#import "ExploreObservationRealm.h"
#import "ImageStore.h"

@implementation ExploreObservationPhotoRealm

+ (NSDictionary *)valueForMantleModel:(ExploreObservationPhoto *)model {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    
    value[@"url"] = model.url;
    value[@"observationPhotoId"] = @(model.observationPhotoId);
    value[@"position"] = @(model.position);
    value[@"uuid"] = model.uuid;

    return [NSDictionary dictionaryWithDictionary:value];
}

+ (NSDictionary *)valueForCoreDataModel:(id)cdModel {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    
    if ([cdModel valueForKey:@"recordID"]) {
        value[@"observationPhotoId"] = [cdModel valueForKey:@"recordID"];
    } else {
        value[@"observationPhotoId"] = @(0);
    }
    
    if ([cdModel valueForKey:@"position"]) {
        value[@"position"] = [cdModel valueForKey:@"position"];
    } else {
        value[@"position"] = @(0);
    }

    value[@"url"] = [cdModel valueForKey:@"squareURL"];
    value[@"uuid"] = [cdModel valueForKey:@"uuid"];
    value[@"timeSynced"] = [cdModel valueForKey:@"syncedAt"];
    value[@"timeCreated"] = [cdModel valueForKey:@"createdAt"];
    value[@"photoKey"] = [cdModel valueForKey:@"photoKey"];

    return value;
}


#pragma mark - INATPhoto
- (NSURL *)largePhotoUrl {
    return [NSURL URLWithString:[self urlStringForSize:@"large"]];
}

- (NSURL *)mediumPhotoUrl {
    return [NSURL URLWithString:[self urlStringForSize:@"medium"]];
}

- (NSURL *)smallPhotoUrl {
    return [NSURL URLWithString:[self urlStringForSize:@"small"]];
}

- (NSURL *)thumbPhotoUrl {
    return [NSURL URLWithString:[self urlStringForSize:@"thumb"]];
}

- (NSURL *)squarePhotoUrl {
    return [NSURL URLWithString:self.url];
}

- (NSString *)urlStringForSize:(NSString *)size {
    return [self.url stringByReplacingOccurrencesOfString:@"square" withString:size];
}

#pragma mark - Uploadable

- (NSArray *)childrenNeedingUpload {
    return @[ ];
}

- (BOOL)needsUpload {
    return self.timeSynced == nil || [self.timeSynced timeIntervalSinceDate:self.timeUpdatedLocally] < 0;
}

+ (NSArray *)needingUpload {
    // observations (the parent object) take care of this
    return @[ ];
}

- (NSDictionary *)uploadableRepresentation {
    NSDictionary *mapping = @{
                              @"position": @"observation_photo[position]",
                              @"uuid": @"observation_photo[uuid]",
                              };
    
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    for (NSString *key in mapping) {
        if ([self valueForKey:key]) {
            NSString *mappedName = mapping[key];
            mutableParams[mappedName] = [self valueForKey:key];
        }
    }

    ExploreObservationRealm *o = [[self observations] firstObject];
    mutableParams[@"observation_photo[observation_id]"] = @(o.observationId);
        
    // return an immutable copy
    return [NSDictionary dictionaryWithDictionary:mutableParams];
}

+ (NSString *)endpointName {
    return @"observation_photos";
}

// should take an error
- (NSString *)fileUploadParameter {
    NSString *path = [[ImageStore sharedImageStore] pathForKey:self.photoKey
                                                       forSize:ImageStoreLargeSize];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // if we can't get the large, try the small
    if (!path || ! [fm fileExistsAtPath:path]) {
        path = [[ImageStore sharedImageStore] pathForKey:self.photoKey
                                                 forSize:ImageStoreSmallSize];
    }
    
    // if we don't have any files for this obs photo, it's not in the ImageStore
    if (!path || ![fm fileExistsAtPath:path]) {
        return nil;
    } else {
        return path;
    }
}

-(void)setRecordId:(NSInteger)newRecordId {
    self.observationPhotoId = newRecordId;
}

- (NSInteger)recordId {
    return self.observationPhotoId;
}

+ (NSDictionary *)linkingObjectsProperties {
    return @{
        @"observations": [RLMPropertyDescriptor descriptorWithClass:ExploreObservationRealm.class propertyName:@"observationPhotos"],
    };
}

+ (void)syncedDelete:(ExploreObservationPhotoRealm *)model {
    // delete the associated photo in the imagestore
    [model deleteFileSystemAssociations];

    // create a deleted record for the observation
    ExploreDeletedRecord *dr = [model deletedRecordForModel];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    // insert the deleted obs
    [realm addOrUpdateObject:dr];
    // delete the model object
    [realm deleteObject:model];
    [realm commitWriteTransaction];
}

+ (void)deleteWithoutSync:(ExploreObservationPhotoRealm *)model {
    // delete the associated photo in the imagestore
    [model deleteFileSystemAssociations];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    // delete the model object
    [realm deleteObject:model];
    [realm commitWriteTransaction];
}

- (ExploreDeletedRecord *)deletedRecordForModel {
    ExploreDeletedRecord *dr = [[ExploreDeletedRecord alloc] initWithRecordId:self.recordId
                                                                    modelName:@"ObservationPhoto"];
    dr.endpointName = [self.class endpointName];
    dr.synced = NO;
    return dr;
}

- (void)deleteFileSystemAssociations {
    // would be nice if realm had a pre-delete hook like core data's
    // -preapreForDeletion
    [[ImageStore sharedImageStore] destroy:self.photoKey];
}


@end
