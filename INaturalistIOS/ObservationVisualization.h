//
//  ObservationVisualization.h
//  iNaturalist
//
//  Created by Alex Shepard on 3/1/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreLocation;

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
- (NSInteger)taxonID;
- (NSString *)inatDescription;

- (CLLocationDegrees)latitude;
- (CLLocationDegrees)longitude;
- (CLLocationAccuracy)positionalAccuracy;

- (CLLocationDegrees)privateLatitude;
- (CLLocationDegrees)privateLongitude;
- (CLLocationAccuracy)privatePositionalAccuracy;

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

- (BOOL)hasUnviewedActivity;

- (Taxon *)taxon;
- (void)setTaxon:(Taxon *)newValue;

- (NSString *)sortable;
- (NSString *)uuid;
- (NSString *)validationErrorMsg;
- (BOOL)captive;

@end
