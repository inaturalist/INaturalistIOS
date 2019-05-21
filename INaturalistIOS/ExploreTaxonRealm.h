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

@property NSInteger taxonId;
@property NSString *webContent;
@property NSString *commonName;
@property NSString *scientificName;
@property NSString *searchableCommonName;
@property NSString *searchableScientificName;
@property NSString *photoUrlString;
@property (readonly) NSURL *photoUrl;
@property NSString *rankName;
@property NSInteger rankLevel;
@property NSString *iconicTaxonName;
@property NSString *lastMatchedTerm;
@property NSString *searchableLastMatchedTerm;
@property NSInteger observationCount;
@property NSString *wikipediaUrlString;
@property (readonly) NSURL *wikipediaUrl;

// to-many relationships
@property RLMArray<ExploreTaxonPhotoRealm *><ExploreTaxonPhotoRealm> *taxonPhotos;


- (BOOL)isGenusOrLower;
- (instancetype)initWithMantleModel:(ExploreTaxon *)model;
- (NSAttributedString *)wikipediaSummaryAttrStringWithSystemFontSize:(CGFloat)fontSize;

@end
