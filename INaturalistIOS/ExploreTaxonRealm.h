//
//  ExploreTaxonRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 6/25/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>
#import "ExploreTaxon.h"
#import "ExploreTaxonPhotoRealm.h"
#import "TaxonVisualization.h"

@interface ExploreTaxonRealm : RLMObject <TaxonVisualization>

@property (nonatomic, assign) NSInteger taxonId;
@property (nonatomic, copy) NSString *webContent;
@property (nonatomic, copy) NSString *commonName;
@property (nonatomic, copy) NSString *scientificName;
@property (nonatomic, copy) NSString *searchableCommonName;
@property (nonatomic, copy) NSString *searchableScientificName;
@property (nonatomic, copy) NSString *photoUrlString;
@property (nonatomic, readonly) NSURL *photoUrl;
@property (nonatomic, copy) NSString *rankName;
@property (nonatomic, assign) NSInteger rankLevel;
@property (nonatomic, copy) NSString *iconicTaxonName;
@property (nonatomic, copy) NSString *lastMatchedTerm;
@property (nonatomic, copy) NSString *searchableLastMatchedTerm;
@property (nonatomic, assign) NSInteger observationCount;

// to-many relationships
@property RLMArray<ExploreTaxonPhotoRealm *><ExploreTaxonPhotoRealm> *taxonPhotos;


- (BOOL)isGenusOrLower;
- (instancetype)initWithMantleModel:(ExploreTaxon *)model;

@end
