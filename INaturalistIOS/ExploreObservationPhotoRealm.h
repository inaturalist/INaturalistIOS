//
//  ExploreObservationPhotoRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 8/9/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>

#import "INatPhoto.h"

@class ExploreObservationPhoto;

@interface ExploreObservationPhotoRealm : RLMObject <INatPhoto>

@property NSString *url;
@property NSString *photoKey;

- (instancetype)initWithMantleModel:(ExploreObservationPhoto *)model;

@end

// allows to-many relationships to this class
RLM_ARRAY_TYPE(ExploreObservationPhotoRealm)