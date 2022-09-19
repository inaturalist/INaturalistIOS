//
//  ExploreIdentificationRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 10/17/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>

#import "ExploreIdentification.h"
#import "ExploreUserRealm.h"
#import "ExploreTaxonRealm.h"
#import "IdentificationVisualization.h"

@interface ExploreIdentificationRealm : RLMObject <IdentificationVisualization>

@property NSInteger identificationId;
@property NSString *identificationBody;
@property BOOL identificationIsCurrent;
@property NSDate *identifiedDate;

@property ExploreUserRealm *identifier;
@property ExploreTaxonRealm *taxon;

@property (readonly) RLMLinkingObjects *observations;

- (instancetype)initWithMantleModel:(ExploreIdentification *)model;
+ (NSDictionary *)valueForMantleModel:(ExploreIdentification *)model;
+ (NSDictionary *)valueForCoreDataModel:(id)cdModel;

@end

RLM_COLLECTION_TYPE(ExploreIdentificationRealm)
