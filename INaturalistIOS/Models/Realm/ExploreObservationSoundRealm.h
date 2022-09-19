//
//  ExploreObservationSoundRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/3/21.
//  Copyright © 2021 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>

#import "INatSound.h"
#import "ExploreObservationSound.h"
#import "Uploadable.h"

@interface ExploreObservationSoundRealm : RLMObject <INatSound, Uploadable>

@property NSString *mediaUrlString;
@property NSInteger observationSoundId;
@property NSString *uuid;

@property NSDate *timeSynced;
@property NSDate *timeUpdatedLocally;

+ (NSDictionary *)valueForMantleModel:(ExploreObservationSound *)model;

@property (readonly) RLMLinkingObjects *observations;

@end

RLM_COLLECTION_TYPE(ExploreObservationSoundRealm)

