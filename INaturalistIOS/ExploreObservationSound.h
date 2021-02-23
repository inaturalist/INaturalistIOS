//
//  ExploreObservationSound.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/3/21.
//  Copyright © 2021 iNaturalist. All rights reserved.
//

#import <Mantle/Mantle.h>

#import "INatSound.h"

@interface ExploreObservationSound : MTLModel <MTLJSONSerializing, INatSound>

@property (nonatomic, copy) NSString *mediaUrlString;
@property (nonatomic, assign) NSInteger observationSoundId;
@property (nonatomic, copy) NSString *uuid;

@end
