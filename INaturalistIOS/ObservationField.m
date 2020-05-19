//
//  ObservationField.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/12/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "ObservationField.h"

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

- (NSArray *)allowedValuesArray
{
    return self.allowedValues ? [self.allowedValues componentsSeparatedByString:@"|"] : [[NSArray alloc] init];
}

@end
