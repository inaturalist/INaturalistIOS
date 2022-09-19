//
//  ObserverCount.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@class ExploreUser;

@interface ObserverCount : MTLModel <MTLJSONSerializing>

@property ExploreUser *observer;
@property NSInteger observationCount;
@property NSInteger speciesCount;

@end
