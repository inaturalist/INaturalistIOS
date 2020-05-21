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
    
    // uuid is the primary key, cannot be nil
    if (mtlModel.uuid) {
        value[@"uuid"] = mtlModel.uuid;
    } else {
        value[@"uuid"] = [[[NSUUID UUID] UUIDString] lowercaseString];
    }
    
    if (mtlModel.obsField) {
        value[@"obsField"] = [ExploreObsFieldRealm valueForMantleModel:mtlModel.obsField];
    }
    
    value[@"timeSynced"] = [NSDate date];
    value[@"timeUpdatedLocally"] = nil;
    
    return [NSDictionary dictionaryWithDictionary:value];
}

+ (NSDictionary *)valueForCoreDataModel:(id)cdModel {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    value[@"obsFieldValueId"] = [cdModel valueForKey:@"recordID"];
    
    // as if this isn't confusing enough already, this naming scheme overlap
    // sorry!
    if ([cdModel valueForKey:@"value"]) {
        value[@"value"] = [cdModel valueForKey:@"value"];
    }
        
    // uuid is the primary key, cannot be nil
    // however, we don't have UUIDs for obsFieldValues in CoreData
    // so just make one up for now. it will get reset next time the
    // observation syncs
    // TODO: this is only safe if the cdModel was not previously synced
    value[@"uuid"] = [[[NSUUID UUID] UUIDString] lowercaseString];
    
    if ([cdModel valueForKey:@"observationField"]) {
        value[@"obsField"] = [ExploreObsFieldRealm valueForCoreDataModel:[cdModel valueForKey:@"observationField"]];
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


@end
