//
//  ExploreObservationPhotoRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/2/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>

#import "INatPhoto.h"
#import "ExploreObservationPhoto.h"
#import "Uploadable.h"

@interface ExploreObservationPhotoRealm : RLMObject <INatPhoto, Uploadable>

@property NSString *uuid;
@property NSInteger position;
@property NSString *photoKey;
@property NSInteger observationPhotoId;
@property NSString *url;
@property NSDate *timeCreated;
@property NSDate *timeSynced;
@property NSDate *timeUpdatedLocally;

@property (readonly) RLMLinkingObjects *observations;


+ (NSDictionary *)valueForMantleModel:(ExploreObservationPhoto *)model;
+ (NSDictionary *)valueForCoreDataModel:(id)model;

@end

RLM_COLLECTION_TYPE(ExploreObservationPhotoRealm)
