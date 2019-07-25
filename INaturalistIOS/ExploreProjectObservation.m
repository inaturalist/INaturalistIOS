//
//  ExploreProjectObservation.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/28/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import "ExploreProjectObservation.h"

@implementation ExploreProjectObservation

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"recordId": @"id",
             @"uuid": @"uuid",
             @"projectId": @"project.id",
             };
}

@end
