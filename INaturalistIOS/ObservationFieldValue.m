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
#import "Analytics.h"

static RKManagedObjectMapping *defaultMapping = nil;
static RKObjectMapping *defaultSerializationMapping = nil;

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

+ (RKManagedObjectMapping *)mapping
{
    if (!defaultMapping) {
        defaultMapping = [RKManagedObjectMapping mappingForClass:[ObservationFieldValue class]
                                            inManagedObjectStore:[RKManagedObjectStore defaultObjectStore]];
        [defaultMapping mapKeyPathsToAttributes:
         @"id",                     @"recordID",
         @"created_at_utc",         @"createdAt",
         @"updated_at_utc",         @"updatedAt",
         @"value",                  @"value",
         @"observation_id",         @"observationID",
         @"observation_field_id",   @"observationFieldID",
         nil];
        [defaultMapping mapKeyPath:@"observation_field" 
                    toRelationship:@"observationField" 
                       withMapping:[ObservationField mapping]
                         serialize:NO];
        defaultMapping.primaryKeyAttribute = @"recordID";
    }
    return defaultMapping;
}

+ (RKObjectMapping *)serializationMapping
{
    if (!defaultSerializationMapping) {
        defaultSerializationMapping = [[RKManagedObjectMapping mappingForClass:[ObservationFieldValue class]
                                                          inManagedObjectStore:[RKManagedObjectStore defaultObjectStore]] inverseMapping];
        [defaultSerializationMapping mapKeyPathsToAttributes:
         @"recordID",           @"observation_field_value[id]",
         @"value",              @"observation_field_value[value]",
         @"observationID",      @"observation_field_value[observation_id]",
         @"observationFieldID", @"observation_field_value[observation_field_id]",
         nil];
    }
    return defaultSerializationMapping;
}

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

- (void)willSave
{
    [super willSave];
}

@end
