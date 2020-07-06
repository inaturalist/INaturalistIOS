//
//  ExploreObservationsController.h
//  Explore Prototype
//
//  Created by Alex Shepard on 10/3/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ExploreObservationsDataSource.h"

extern NSInteger const ObsFetchErrorCode;
extern NSInteger const ObsFetchEmptyCode;

@interface ExploreObservationsController : NSObject <ExploreObservationsDataSource>
@end
