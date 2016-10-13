//
//  ObservationVisualization.h
//  iNaturalist
//
//  Created by Alex Shepard on 3/1/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreLocation;

@class ExploreTaxonRealm;
@class Taxon;

typedef NS_ENUM(NSInteger, ObsDataQuality) {
    ObsDataQualityCasual,
    ObsDataQualityNeedsID,
    ObsDataQualityResearch,
    ObsDataQualityNone
};

@protocol ObservationVisualization <NSObject>


- (BOOL)isEditable;
- (NSString *)speciesGuess;
- (NSInteger)taxonRecordID;
- (NSString *)inatDescription;

- (CLLocationCoordinate2D)visibleLocation;
- (CLLocationAccuracy)visiblePositionalAccuracy;

- (NSDate *)observedOn;
- (NSString *)observedOnShortString;

- (NSInteger)userID;
- (NSString *)username;
- (NSURL *)userThumbUrl;

- (NSString *)placeGuess;
- (BOOL)idPlease;
- (NSString *)geoprivacy;
- (NSString *)qualityGrade;
- (ObsDataQuality)dataQuality;

- (NSString *)iconicTaxonName;

- (NSSet *)observationPhotos;
- (NSArray *)sortedObservationPhotos;
- (NSSet *)observationFieldValues;
- (NSSet *)projectObservations;
- (NSSet *)comments;
- (NSSet *)identifications;
- (NSSet *)faves;
- (NSArray *)sortedActivity;
- (NSArray *)sortedFaves;

- (NSInteger)inatRecordId;

- (BOOL)hasUnviewedActivityBool;

- (Taxon *)taxon;
- (void)setTaxon:(Taxon *)newValue;

- (ExploreTaxonRealm *)exploreTaxonRealm;

- (NSString *)sortable;
- (NSString *)uuid;
- (NSString *)validationErrorMsg;
- (BOOL)isCaptive;

@end
