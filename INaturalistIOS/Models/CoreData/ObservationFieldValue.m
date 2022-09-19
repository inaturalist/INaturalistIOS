//
//  ObservationFieldValue.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/12/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "ObservationFieldValue.h"
#import "Observation.h"
#import "ObservationField.h"

@implementation ObservationFieldValue

@dynamic recordID;
@dynamic observationID;
@dynamic observationFieldID;
@dynamic value;
@dynamic createdAt;
@dynamic updatedAt;
@dynamic syncedAt;
@dynamic localCreatedAt;
@dynamic localUpdatedAt;
@dynamic observationField;
@dynamic observation;

- (NSString *)defaultValue
{
    if (self.observationField.allowedValuesArray.count > 0) {
        return [self.observationField.allowedValuesArray objectAtIndex:0];
    } else {
        return @"";
    }
}

- (NSNumber *)observationFieldID
{
    [self willAccessValueForKey:@"observationFieldID"];
    if (!self.primitiveObservationFieldID || [self.primitiveObservationFieldID intValue] == 0) {
        [self willChangeValueForKey:@"observationFieldID"];
        [self setPrimitiveObservationFieldID:self.observationField.recordID];
        [self didChangeValueForKey:@"observationFieldID"];
    }
    [self didAccessValueForKey:@"observationFieldID"];
    return [self primitiveObservationFieldID];
}

- (NSNumber *)observationID
{
    // NOTE: you absolutely have to check to make sure the value you're about to set is nil or not.
    // If you try to set nil on a primitive attribute, you may throw Restkit into an infinite loop
    if (self.observation && self.observation.recordID && (!self.primitiveObservationID || [self.primitiveObservationID intValue] == 0)) {
        [self willChangeValueForKey:@"observationID"];
        [self setPrimitiveObservationID:self.observation.recordID];
        [self didChangeValueForKey:@"observationID"];
    }
    return [self primitiveObservationID];
}

- (NSString *)value
{
    [self willAccessValueForKey:@"value"];
    NSString *v = [self primitiveValueForKey:@"value"];
    [self didAccessValueForKey:@"value"];
    if (!v) {
        v = [self defaultValue];
        [self willChangeValueForKey:@"value"];
        [self setPrimitiveValue:v forKey:@"value"];
        [self didChangeValueForKey:@"value"];
    }
    return v;
}

- (void)setValue:(NSString *)newValue
{
    [self willChangeValueForKey:@"value"];
    [self setPrimitiveValue:[newValue stringByTrimmingCharactersInSet:
                             [NSCharacterSet whitespaceCharacterSet]]];
    [self didChangeValueForKey:@"value"];
}

#pragma mark - Uploadable

+ (NSArray *)needingUpload {
    // observations (the parent object) take care of this
    return @[];
}

- (BOOL)needsUpload {
    return self.needsSync;
}

- (NSArray *)childrenNeedingUpload {
    return @[];
}


- (NSDictionary *)uploadableRepresentation {
    NSDictionary *mapping = @{
                              @"value": @"value",
                              @"observationID": @"observation_id",
                              @"observationFieldID": @"observation_field_id",
                              };
    
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    for (NSString *key in mapping) {
        if ([self valueForKey:key]) {
            NSString *mappedName = mapping[key];
            mutableParams[mappedName] = [self valueForKey:key];
        }
    }
    
    // return an immutable copy
    return @{ @"observation_field_value": [NSDictionary dictionaryWithDictionary:mutableParams] };
}

@end
