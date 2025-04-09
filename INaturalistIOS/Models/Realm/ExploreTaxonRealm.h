//
//  ExploreTaxonRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 6/25/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

@import UIKit;
@import Foundation;
@import Realm;

#import "ExploreTaxon.h"
#import "ExploreTaxonPhotoRealm.h"
#import "TaxonVisualization.h"

@class GuideTaxonXML;

@interface ExploreTaxonRealm : RLMObject <TaxonVisualization>

@property NSInteger taxonId;
@property NSString *webContent;
@property NSString *commonName;
@property NSString *scientificName;
@property NSString *searchableCommonName;
@property NSString *searchableScientificName;
@property NSString *photoUrlString;
@property (readonly) NSURL *photoUrl;
@property NSString *representativePhotoUrlString;
@property (readonly) NSURL *representativePhotoUrl;
@property NSString *rankName;
@property NSInteger rankLevel;
@property NSString *iconicTaxonName;
@property NSString *lastMatchedTerm;
@property NSString *searchableLastMatchedTerm;
@property NSInteger observationCount;
@property NSString *wikipediaUrlString;
@property BOOL isActive;
@property (readonly) NSURL *wikipediaUrl;

// to-many relationships
@property RLMArray<ExploreTaxonPhotoRealm *><ExploreTaxonPhotoRealm> *taxonPhotos;


- (BOOL)isGenusOrLower;
- (BOOL)scientificNameIsItalicized;
- (instancetype)initWithMantleModel:(ExploreTaxon *)model;
+ (NSDictionary *)valueForMantleModel:(ExploreTaxon *)model;
+ (NSDictionary *)valueForCoreDataModel:(id)model;
+ (NSDictionary *)valueForRealmModel:(ExploreTaxonRealm *)model;

- (NSAttributedString *)wikipediaSummaryAttrStringWithSystemFontSize:(CGFloat)fontSize;

@end
