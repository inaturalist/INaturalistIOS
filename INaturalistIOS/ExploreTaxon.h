//
//  ExploreTaxon.h
//  Explore Prototype
//
//  Created by Alex Shepard on 10/13/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@interface ExploreTaxon : MTLModel <MTLJSONSerializing>

@property (nonatomic, assign) NSInteger taxonId;
@property (nonatomic, copy) NSString *webContent;
@property (nonatomic, copy) NSString *commonName;
@property (nonatomic, copy) NSString *scientificName;
@property (nonatomic, copy) NSURL *photoUrl;
@property (nonatomic, copy) NSString *rankName;
@property (nonatomic, assign) NSInteger rankLevel;
@property (nonatomic, copy) NSString *iconicTaxonName;

@end
