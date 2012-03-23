//
//  Observation.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/15/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "INatModel.h"

@class Taxon;

@interface Observation : INatModel

@property (nonatomic, retain) NSString * speciesGuess;
@property (nonatomic, retain) NSNumber * taxonID;
@property (nonatomic, retain) NSString * inatDescription;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * positionalAccuracy;
@property (nonatomic, retain) NSDate * observedOn;
@property (nonatomic, retain) NSDate * localObservedOn;
@property (nonatomic, retain) NSString * observedOnString;
@property (nonatomic, retain) NSDate * timeObservedAt;
@property (nonatomic, retain) NSNumber * userID;
@property (nonatomic, retain) NSString * placeGuess;
@property (nonatomic, retain) NSNumber * idPlease;
@property (nonatomic, retain) NSNumber * iconicTaxonID;
@property (nonatomic, retain) NSString * iconicTaxonName;
@property (nonatomic, retain) NSNumber * privateLatitude;
@property (nonatomic, retain) NSNumber * privateLongitude;
@property (nonatomic, retain) NSNumber * privatePositionalAccuracy;
@property (nonatomic, retain) NSString * geoprivacy;
@property (nonatomic, retain) NSString * qualityGrade;
@property (nonatomic, retain) NSString * positioningMethod;
@property (nonatomic, retain) NSString * positioningDevice;
@property (nonatomic, retain) NSNumber * outOfRange;
@property (nonatomic, retain) NSString * license;
@property (nonatomic, retain) NSSet * observationPhotos;
@property (nonatomic, retain) NSSet * projectObservations;
@property (nonatomic, retain) Taxon *taxon;

+ (NSDateFormatter *)prettyDateFormatter;
+ (NSDateFormatter *)shortDateFormatter;
+ (NSDateFormatter *)isoDateFormatter;
+ (NSDateFormatter *)jsDateFormatter;
- (NSString *)observedOnPrettyString;
- (NSString *)observedOnShortString;
- (UIColor *)iconicTaxonColor;
- (NSArray *)sortedObservationPhotos;
- (NSArray *)sortedProjectObservations;

@end

@interface Observation (PrimitiveAccessors)
- (NSNumber *)primitiveTaxonID;
- (void)setPrimitiveTaxonID:(NSNumber *)newTaxonId;
- (NSNumber *)primitiveIconicTaxonName;
- (void)setPrimitiveIconicTaxonName:(NSNumber *)newIconicTaxonName;
@end

