//
//  ExploreProjectObservationRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 4/27/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import "ExploreProjectObservationRealm.h"
#import "ExploreObservationRealm.h"

@interface ExploreProjectObservationRealm ()
@property (readonly) RLMLinkingObjects *observations;
@end

@implementation ExploreProjectObservationRealm

+ (NSDictionary *)valueForMantleModel:(ExploreProjectObservation *)mtlModel {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    value[@"projectObsId"] = @(mtlModel.projectObsId);
        
    if (mtlModel.uuid) {
        value[@"uuid"] = mtlModel.uuid;
    } else {
        // uuid is the primary key, cannot be nil
        value[@"uuid"] = [[[NSUUID UUID] UUIDString] lowercaseString];
    }
    
    if (mtlModel.project) {
        value[@"project"] = [ExploreProjectRealm valueForMantleModel:mtlModel.project];
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
        value[@"projectObsId"] = [cdModel valueForKey:@"recordID"];
    } else {
        // this is an uploadable, un-uploaded project obs can have a record
        // id of nil/zero
        value[@"projectObsId"] = @(0);
    }
            
    if ([cdModel valueForKey:@"syncedAt"]) {
        // skip this in the migration, since we won't have a UUID for it
        // we'll just refetch from the server the next time the user looks
        // for their observations
        return nil;
    } else {
        // uuid is the primary key, cannot be nil
        // however, we don't have UUIDs for project observations in CoreData
        // so just make one up for now. it will get reset next time the
        // observation syncs
        value[@"uuid"] = [[[NSUUID UUID] UUIDString] lowercaseString];
    }
    
    if ([cdModel valueForKey:@"project"]) {
        id projectValue = [ExploreProjectRealm valueForCoreDataModel:[cdModel valueForKey:@"project"]];
        if (projectValue) {
            value[@"project"] = projectValue;
        } else {
            // we can't migrate a PO without a project
            return nil;
        }
    } else {
        // we can't migrate a PO without a project
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
                                                       propertyName:@"projectObservations"],
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
    // handled by parent obs
    return @[ ];
}

- (NSDictionary *)uploadableRepresentation {
    if (self.observation && self.project) {
        return @{
            @"observation_id": @(self.observation.observationId),
            @"project_id": @(self.project.projectId),
            @"uuid": self.uuid,
        };
    } else {
        return nil;
    }
}

+ (NSString *)endpointName {
    return @"project_observations";
}

- (void)setRecordId:(NSInteger)newRecordId {
    self.projectObsId = newRecordId;
}

- (NSInteger)recordId {
    return self.projectObsId;
}

+ (void)syncedDelete:(ExploreProjectObservationRealm *)model {
    RLMRealm *realm = [model realm];
    if (realm) {
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
}

+ (void)deleteWithoutSync:(ExploreProjectObservationRealm *)model {
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
                                                                    modelName:@"ProjectObservation"];
    dr.endpointName = [self.class endpointName];
    dr.synced = NO;
    return dr;
}



@end
