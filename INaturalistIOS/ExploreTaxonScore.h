//
//  ExploreTaxonScore.h
//  iNaturalist
//
//  Created by Alex Shepard on 6/19/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import <Mantle/Mantle.h>
#import "ExploreTaxon.h"

@interface ExploreTaxonScore : MTLModel <MTLJSONSerializing>
@property ExploreTaxon *exploreTaxon;
@property CGFloat frequencyScore;
@property CGFloat visionScore;
@property CGFloat combinedScore;
@end
