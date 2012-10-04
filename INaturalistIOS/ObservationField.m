//
//  ObservationField.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/12/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "ObservationField.h"

static RKManagedObjectMapping *defaultMapping = nil;
//static RKManagedObjectMapping *defaultSerializationMapping = nil;

@implementation ObservationField

@dynamic recordID;
@dynamic name;
@dynamic datatype;
@dynamic userID;
@dynamic desc;
@dynamic allowedValues;
@dynamic createdAt;
@dynamic updatedAt;
@dynamic localCreatedAt;
@dynamic localUpdatedAt;
@dynamic syncedAt;
@dynamic observationFieldValues;
@dynamic projectObservationFields;

+ (RKManagedObjectMapping *)mapping
{
    if (!defaultMapping) {
        defaultMapping = [RKManagedObjectMapping mappingForClass:[self class] inManagedObjectStore:[RKManagedObjectStore defaultObjectStore]];
        [defaultMapping mapKeyPathsToAttributes:
         @"id",                 @"recordID",
         @"created_at_utc",     @"createdAt",
         @"updated_at_utc",     @"updatedAt",
         @"name",               @"name",
         @"user_id",            @"userID",
         @"allowed_values",     @"allowedValues",
         @"description",        @"desc",
         @"datatype",          @"datatype",
         nil];
        defaultMapping.primaryKeyAttribute = @"recordID";
    }
    return defaultMapping;
}

- (NSArray *)allowedValuesArray
{
    return self.allowedValues ? [self.allowedValues componentsSeparatedByString:@"|"] : [[NSArray alloc] init];
}

@end
