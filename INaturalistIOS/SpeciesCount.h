//
//  SpeciesCount.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@class ExploreTaxon;

@interface SpeciesCount : MTLModel <MTLJSONSerializing>

@property NSInteger speciesCount;
@property ExploreTaxon *taxon;

- (BOOL)isGenusOrLower;

@end
