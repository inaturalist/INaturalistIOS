//
//  ExploreFave.h
//  iNaturalist
//
//  Created by Alex Shepard on 3/8/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

#import "FaveVisualization.h"

@class ExploreUser;

@interface ExploreFave : MTLModel <FaveVisualization, MTLJSONSerializing>

@property (nonatomic, retain) ExploreUser *faver;
@property (nonatomic, copy) NSDate *faveDate;

@end
