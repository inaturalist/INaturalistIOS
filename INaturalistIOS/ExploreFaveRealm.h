//
//  ExploreFaveRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 1/12/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>

#import "ExploreFave.h"
#import "FaveVisualization.h"
#import "ExploreUserRealm.h"

@interface ExploreFaveRealm : RLMObject <FaveVisualization>

@property NSInteger faveId;
@property ExploreUserRealm *faver;
@property NSDate *faveDate;

- (instancetype)initWithMantleModel:(ExploreFave *)model;

@end

RLM_ARRAY_TYPE(ExploreFaveRealm)
