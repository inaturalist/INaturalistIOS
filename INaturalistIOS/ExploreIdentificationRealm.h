//
//  ExploreIdentificationRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 8/9/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>

#import "IdentificationVisualization.h"
#import "ActivityVisualization.h"

@class ExploreUserRealm;
@class ExploreTaxonRealm;
@class ExploreIdentification;

@interface ExploreIdentificationRealm : RLMObject <ActivityVisualization, IdentificationVisualization>

@property NSInteger identificationId;
@property NSString *identificationBody;
@property BOOL identificationIsCurrent;
@property NSDate *identifiedDate;

@property ExploreUserRealm *identifier;
@property ExploreTaxonRealm *taxon;

- (instancetype)initWithMantleModel:(ExploreIdentification *)model;

@end

// allows to-many relationships to this class
RLM_ARRAY_TYPE(ExploreIdentificationRealm)
