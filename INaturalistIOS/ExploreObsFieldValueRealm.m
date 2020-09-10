//
//  ExploreObsFieldValueRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 4/26/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import "ExploreObsFieldValueRealm.h"
#import "ExploreObservationRealm.h"

@interface ExploreObsFieldValueRealm ()
@property (readonly) RLMLinkingObjects *observations;
@end


@implementation ExploreObsFieldValueRealm

+ (NSDictionary *)valueForMantleModel:(ExploreObsFieldValue *)mtlModel {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    value[@"obsFieldValueId"] = @(mtlModel.obsFieldValueId);
    
    // as if this isn't confusing enough already, this naming scheme overlap
    // sorry!
    if (mtlModel.value) {
        value[@"value"] = mtlModel.value;
    }
    
    if (mtlModel.uuid) {
        value[@"uuid"] = mtlModel.uuid;
    } else {
        // uuid is the primary key, cannot be nil
        value[@"uuid"] = [[[NSUUID UUID] UUIDString] lowercaseString];
    }
    
    if (mtlModel.obsField) {
        value[@"obsField"] = [ExploreObsFieldRealm valueForMantleModel:mtlModel.obsField];
    }
    
    // synced from node to mantle now
    value[@"timeSynced"] = [NSDate date];
    // no local changes yet
    value[@"timeUpdatedLocally"] = nil;

    return [NSDictionary dictionaryWithDictionary:value];
}

+ (NSDictionary *)valueForCoreDataModel:(id)cdModel {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    if ([cdModel valueForKey:@"recordID"]) {
        value[@"obsFieldValueId"] = [cdModel valueForKey:@"recordID"];
    } else {
        // this is an uploadable, un-uploaded OFVs can have a record
        // id of nil/zero
        value[@"obsFieldValueId"] = @(0);
    }
    
    // as if this isn't confusing enough already, this naming scheme overlap
    // sorry!
    if ([cdModel valueForKey:@"value"]) {
        value[@"value"] = [cdModel valueForKey:@"value"];
    } else {
        // we can't migrate an OFV without a value
        return nil;
    }
    
    if ([cdModel valueForKey:@"syncedAt"]) {
        // skip this in the migration, since we won't have a UUID for it
        // we'll just refetch from the server the next time the user looks
        // for their observations
        return nil;
    } else {
        // uuid is the primary key, cannot be nil
        // however, we don't have UUIDs for obsFieldValues in CoreData
        // so just make one up for now. it will get reset next time the
        // observation syncs
        // this is only safe if the cdModel was not previously synced
        value[@"uuid"] = [[[NSUUID UUID] UUIDString] lowercaseString];
    }

    if ([cdModel valueForKey:@"observationField"]) {
        value[@"obsField"] = [ExploreObsFieldRealm valueForCoreDataModel:[cdModel valueForKey:@"observationField"]];
    } else {
        // we can't migration an OFV without an obs field
        return nil;
    }
    
    if ([cdModel valueForKey:@"syncedAt"]) {
        value[@"timeSynced"] = [cdModel valueForKey:@"syncedAt"];
    }
    
    if ([cdModel valueForKey:@"localUpdatedAt"]) {
        value[@"timeUpdatedLocally"] = [cdModel valueForKey:@"localUpdatedAt"];
    }
    
    return [NSDictionary dictionaryWithDictionary:value];
}

+ (NSString *)primaryKey {
    return @"uuid";
}

+ (NSDictionary *)linkingObjectsProperties {
    return @{
        @"observations": [RLMPropertyDescriptor descriptorWithClass:ExploreObservationRealm.class
                                                       propertyName:@"observationFieldValues"],
    };
}

- (ExploreObservationRealm *)observation {
    // should only be one observation attached to this linking object property
    return [self.observations firstObject];
}

#pragma mark - Uploadable

- (NSArray *)childrenNeedingUpload {
    return @[ ];
}

- (BOOL)needsUpload {
    return self.timeSynced == nil || [self.timeSynced timeIntervalSinceDate:self.timeUpdatedLocally] < 0;
}

+ (NSArray *)needingUpload {
    return @[ ];
}

- (NSDictionary *)uploadableRepresentation {
    if (self.obsField && self.observation) {
        return @{
            @"observation_field_value": @{
                    @"uuid": self.uuid,
                    @"value": self.value,
                    @"observation_id": @(self.observation.observationId),
                    @"observation_field_id": @(self.obsField.obsFieldId),
            },
        };
    } else {
        return nil;
    }
}

+ (NSString *)endpointName {
    return @"observation_field_values";
}

- (void)setRecordId:(NSInteger)newRecordId {
    self.obsFieldValueId = newRecordId;
}

- (NSInteger)recordId {
    return self.obsFieldValueId;
}

+ (void)syncedDelete:(ExploreObsFieldValueRealm *)model {
    
    RLMRealm *realm = [model realm];
    if (realm) {
        // create a deleted record for the observation
        ExploreDeletedRecord *dr = [model deletedRecordForModel];

        [realm beginWriteTransaction];
        // insert the deleted obs
        [realm addOrUpdateObject:dr];
        // delete the model object
        [realm deleteObject:model];
        [realm commitWriteTransaction];
    }
}

+ (void)deleteWithoutSync:(ExploreObsFieldValueRealm *)model {
    if (model.realm) {
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        // delete the model object
        [realm deleteObject:model];
        [realm commitWriteTransaction];
    }
}

- (ExploreDeletedRecord *)deletedRecordForModel {
    ExploreDeletedRecord *dr = [[ExploreDeletedRecord alloc] initWithRecordId:self.recordId
                                                                    modelName:@"ObservationFieldValue"];
    dr.endpointName = [self.class endpointName];
    dr.synced = NO;
    return dr;
}


@end
