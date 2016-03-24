//
//  ObservationVisualization.h
//  iNaturalist
//
//  Created by Alex Shepard on 3/1/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

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
- (NSNumber *)taxonID;
- (NSString *)inatDescription;

- (NSNumber *)latitude;
- (NSNumber *)longitude;
- (NSNumber *)positionalAccuracy;

- (NSNumber *)privateLatitude;
- (NSNumber *)privateLongitude;
- (NSNumber *)privatePositionalAccuracy;

- (NSDate *)observedOn;
- (NSString *)observedOnShortString;

- (NSNumber *)userID;
- (NSString *)username;
- (NSString *)userThumbUrl;

- (NSString *)placeGuess;
- (NSNumber *)idPlease;
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

- (NSNumber *)inatRecordId;

- (NSNumber *)hasUnviewedActivity;

- (Taxon *)taxon;
- (void)setTaxon:(Taxon *)newValue;

- (NSString *)sortable;
- (NSString *)uuid;
- (NSString *)validationErrorMsg;
- (NSString *)captive;

@end
