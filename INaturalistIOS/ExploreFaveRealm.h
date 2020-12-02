//
//  ExploreFaveRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/3/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>

#import "ExploreUserRealm.h"
#import "FaveVisualization.h"
#import "ExploreFave.h"

@interface ExploreFaveRealm : RLMObject <FaveVisualization>

@property ExploreUserRealm *faver;
@property NSDate *faveDate;
@property NSInteger faveId;

@property (readonly) RLMLinkingObjects *observations;

+ (NSDictionary *)valueForMantleModel:(ExploreFave *)model;

@end

RLM_ARRAY_TYPE(ExploreFaveRealm)
