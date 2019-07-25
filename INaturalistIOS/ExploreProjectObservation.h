//
//  ExploreProjectObservation.h
//  iNaturalist
//
//  Created by Alex Shepard on 5/28/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import "MTLModel.h"

#import "ExploreProject.h"
#import "ExploreObservation.h"

@interface ExploreProjectObservation : MTLModel <MTLJSONSerializing>

@property NSInteger recordId;
@property NSString *uuid;
@property NSInteger projectId;

@end


