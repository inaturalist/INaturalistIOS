//
//  ExploreObservationFieldValue.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/11/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import "ExploreObservationFieldValue.h"

@implementation ExploreObservationFieldValue

+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{
             @"fieldId": @"field_id",
             @"uuid": @"uuid",
             @"value": @"value",
             };
}

@end
