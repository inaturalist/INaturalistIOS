//
//  SpeciesCount.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Taxon;

@interface SpeciesCount : NSObject

@property NSString *scientificName;
@property NSString *commonName;
@property NSInteger taxonId;
@property NSInteger speciesCount;
@property NSString *squarePhotoUrl;

@property NSInteger speciesRankLevel;
@property NSString *speciesRank;

- (BOOL)isGenusOrLower;

@end
