//
//  ExploreFaveRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 8/9/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>

#import "ExploreUserRealm.h"
#import "ExploreFave.h"

@interface ExploreFaveRealm : RLMObject <FaveVisualization>

@property ExploreUserRealm *faver;
@property NSDate *faveDate;

- (instancetype)initWithMantleModel:(ExploreFave *)model;

@end

// allows to-many relationships to this class
RLM_ARRAY_TYPE(ExploreFaveRealm)