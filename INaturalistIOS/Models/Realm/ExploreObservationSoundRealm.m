//
//  ExploreObservationSoundRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/3/21.
//  Copyright © 2021 iNaturalist. All rights reserved.
//

#import "ExploreObservationSoundRealm.h"
#import "ExploreObservationRealm.h"
#import "iNaturalist-Swift.h"

@implementation ExploreObservationSoundRealm

+ (NSDictionary *)valueForMantleModel:(ExploreObservationSound *)model {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    
    value[@"mediaUrlString"] = model.mediaUrlString;
    value[@"observationSoundId"] = @(model.observationSoundId);
    value[@"uuid"] = model.uuid;

    return [NSDictionary dictionaryWithDictionary:value];
}

+ (NSString *)primaryKey {
    return @"uuid";
}

+ (NSDictionary *)linkingObjectsProperties {
    return @{
        @"observations": [RLMPropertyDescriptor descriptorWithClass:ExploreObservationRealm.class propertyName:@"observationSounds"],
    };
}

#pragma mark - INatSound

- (NSURL *)mediaUrl {
    return [NSURL URLWithString:self.mediaUrlString];
}

- (NSString *)mediaKey {
    return self.uuid;
}

#pragma mark - Uploadable

-(NSArray *)childrenNeedingUpload {
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
    mutableParams[@"observation_sound[observation_id]"] = @(o.observationId);
        
    // return an immutable copy
    return [NSDictionary dictionaryWithDictionary:mutableParams];
}

-(void)setRecordId:(NSInteger)newRecordId {
    self.observationSoundId = newRecordId;
}

- (NSInteger)recordId {
    return self.observationSoundId;
}

+ (NSString *)endpointName {
    return @"observation_sounds";
}

// should take an error
- (NSString *)fileUploadParameter {
    
    MediaStore *ms = [[MediaStore alloc] init];
    NSString *path = [ms mediaPathForKey:self.mediaKey];

    NSFileManager *fm = [NSFileManager defaultManager];
    
    // if we don't have any files for this media item,
    // then it's not in the store
    if (!path || ! [fm fileExistsAtPath:path]) {
        return nil;
    } else {
        return path;
    }
}

- (void)deleteFileSystemAssociations {
    MediaStore *ms = [[MediaStore alloc] init];
    [ms destroyMediaKey:self.mediaKey];
}

- (ExploreDeletedRecord *)deletedRecordForModel {
    ExploreDeletedRecord *dr = [[ExploreDeletedRecord alloc] initWithRecordId:self.recordId
                                                                    modelName:@"ObservationSound"];
    dr.endpointName = [self.class endpointName];
    dr.synced = NO;
    return dr;
}

+ (void)syncedDelete:(ExploreObservationSoundRealm *)model {
    // delete the associated sound file in the media store
    [model deleteFileSystemAssociations];
    
    RLMRealm *realm  = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm addOrUpdateObject:[model deletedRecordForModel]];
    [realm commitWriteTransaction];
    
    if ([model realm]) {
        // model has made it into realm, delete it
        [[model realm] beginWriteTransaction];
        [[model realm] deleteObject:model];
        [[model realm] commitWriteTransaction];
    } else {
        // model is still standalone, can happen
        // look for it in the default realm,
        // delete it there
        RLMRealm *realm = [RLMRealm defaultRealm];
        ExploreObservationPhotoRealm *modelInRealm = [ExploreObservationPhotoRealm objectForPrimaryKey:model.uuid];
        if (modelInRealm) {
            [realm beginWriteTransaction];
            [realm deleteObject:modelInRealm];
            [realm commitWriteTransaction];
        }
    }
}

+ (void)deleteWithoutSync:(ExploreObservationSoundRealm *)model {
    // delete the associated photo in the imagestore
    [model deleteFileSystemAssociations];
    
    if (model.realm) {
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        // delete the model object
        [realm deleteObject:model];
        [realm commitWriteTransaction];
    }
}

- (NSString *)fileName {
    return @"original.m4a";
}

- (NSString *)mimeType {
    return @"audio/m4a";
}



@end
