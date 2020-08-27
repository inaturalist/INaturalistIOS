//
//  ObservationVisualization.h
//  iNaturalist
//
//  Created by Alex Shepard on 3/1/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TaxonVisualization.h"

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

- (BOOL)coordinatesObscuredToUser;
- (NSString *)qualityGrade;
- (ObsDataQuality)dataQuality;

- (NSString *)iconicTaxonName;

- (NSSet *)observationPhotos;
- (NSArray *)sortedObservationPhotos;
- (NSSet *)observationFieldValues;
- (NSSet *)projectObservations;
- (NSArray *)sortedProjectObservations;
- (NSSet *)comments;
- (NSSet *)identifications;
- (NSSet *)faves;
- (NSArray *)sortedActivity;
- (NSArray *)sortedFaves;
- (NSInteger)activityCount;

- (NSInteger)inatRecordId;

- (BOOL)hasUnviewedActivityBool;

- (id <TaxonVisualization>)taxon;
- (void)setTaxon:(id <TaxonVisualization>)newValue;

- (ExploreTaxonRealm *)exploreTaxonRealm;

- (NSString *)sortable;
- (NSString *)uuid;
- (NSString *)validationErrorMsg;
- (BOOL)isCaptive;

@end
