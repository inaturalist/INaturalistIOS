//
//  ExploreTaxonScore.m
//  iNaturalist
//
//  Created by Alex Shepard on 6/19/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import "ExploreTaxonScore.h"

@implementation ExploreTaxonScore

+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{
             @"exploreTaxon": @"taxon",
             @"frequencyScore": @"frequency_score",
             @"visionScore": @"vision_score",
             @"combinedScore": @"combined_score",
             };
}

+ (NSValueTransformer *)exploreTaxonJSONTransformer {
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:ExploreTaxon.class];
}

@end
