//
//  ExploreObservationPhotoRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 1/12/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>

#import "ExploreObservationPhoto.h"
#import "INatPhoto.h"
#import "Uploadable.h"

@interface ExploreObservationPhotoRealm : RLMObject <INatPhoto, Uploadable>

@property NSInteger observationPhotoId;
@property NSInteger position;
@property NSString *uuid;
@property NSString *licenseCode;
@property NSString *urlString;
@property NSString *attribution;
@property NSString *photoKey;

@property (readonly) NSURL *url;

@property NSDate *updatedAt;
@property NSDate *syncedAt;

- (instancetype)initWithMantleModel:(ExploreObservationPhoto *)model;

@property (readonly) RLMLinkingObjects *observations;

@end

RLM_ARRAY_TYPE(ExploreObservationPhotoRealm)
