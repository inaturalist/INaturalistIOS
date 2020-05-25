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
        
    // uuid is the primary key, cannot be nil
    if (mtlModel.uuid) {
        value[@"uuid"] = mtlModel.uuid;
    } else {
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
        value[@"projectObsId"] = @(0);
    }
            
    // uuid is the primary key, cannot be nil
    // however, we don't have UUIDs for project observations in CoreData
    // so just make one up for now. it will get reset next time the
    // observation syncs
    if (![cdModel valueForKey:@"syncedAt"]) {
        value[@"uuid"] = [[[NSUUID UUID] UUIDString] lowercaseString];
    }
    
    if ([cdModel valueForKey:@"project"]) {
        value[@"project"] = [ExploreProjectRealm valueForCoreDataModel:[cdModel valueForKey:@"project"]];
    }
    
    value[@"timeSynced"] = [cdModel valueForKey:@"syncedAt"];
    value[@"timeUpdatedLocally"] = [cdModel valueForKey:@"localUpdatedAt"];
    
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

+ (void)deleteWithoutSync:(ExploreProjectObservationRealm *)model {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    // delete the model object
    [realm deleteObject:model];
    [realm commitWriteTransaction];
}

- (ExploreDeletedRecord *)deletedRecordForModel {
    ExploreDeletedRecord *dr = [[ExploreDeletedRecord alloc] initWithRecordId:self.recordId
                                                                    modelName:@"ProjectObservation"];
    dr.endpointName = [self.class endpointName];
    dr.synced = NO;
    return dr;
}



@end
