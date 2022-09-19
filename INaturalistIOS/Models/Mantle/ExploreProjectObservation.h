//
//  ExploreProjectObservation.h
//  iNaturalist
//
//  Created by Alex Shepard on 4/21/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import <Mantle/Mantle.h>

#import "ExploreProject.h"

@interface ExploreProjectObservation : MTLModel <MTLJSONSerializing>

@property (nonatomic, assign) NSInteger projectObsId;
@property (nonatomic, copy) NSString *uuid;
@property ExploreProject *project;

@end
