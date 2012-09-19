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

//static RKManagedObjectMapping *defaultMapping = nil;
//static RKManagedObjectMapping *defaultSerializationMapping = nil;

@implementation ObservationFieldValue

@dynamic recordID;
@dynamic observationID;
@dynamic observationFieldID;
@dynamic value;
@dynamic createdAt;
@dynamic updatedAt;
@dynamic localCreatedAt;
@dynamic localUpdatedAt;
@dynamic observationField;
@dynamic observation;

- (NSString *)defaultValue
{
    if (self.observationField.allowedValuesArray.count > 0) {
        return [self.observationField.allowedValuesArray objectAtIndex:0];
    } else {
        return nil;
    }
}

@end
