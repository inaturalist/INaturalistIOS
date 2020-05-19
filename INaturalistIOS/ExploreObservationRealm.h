//
//  ExploreObservationRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 1/31/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>
#import <CoreLocation/CoreLocation.h>

#import "ExploreObservation.h"
#import "ExploreTaxonRealm.h"
#import "ObservationVisualization.h"
#import "ExploreCommentRealm.h"
#import "ExploreIdentificationRealm.h"
#import "ExploreObservationPhotoRealm.h"
#import "ExploreUserRealm.h"
#import "Uploadable.h"
#import "ExploreFaveRealm.h"
#import "ExploreUpdateRealm.h"
#import "ExploreObsFieldValueRealm.h"
#import "ExploreProjectObservationRealm.h"

@interface ExploreObservationRealm : RLMObject <ObservationVisualization, Uploadable>

@property NSInteger observationId;
@property NSString *uuid;
@property NSString *speciesGuess;
@property ExploreTaxonRealm *taxon;
@property NSString *inatDescription;
@property NSDate *timeObserved;
@property NSDate *timeCreated;
@property NSDate *timeSynced;
@property NSDate *timeUpdatedLocally;

@property ObsDataQuality dataQuality;

@property CLLocationDegrees publicLatitude;
@property CLLocationDegrees publicLongitude;
@property CLLocationAccuracy publicPositionalAccuracy;

@property CLLocationDegrees privateLatitude;
@property CLLocationDegrees privateLongitude;
@property CLLocationAccuracy privatePositionalAccuracy;

@property BOOL coordinatesObscuredToUser;
@property NSString *placeGuess;

@property (readonly) CLLocationDegrees latitude;
@property (readonly) CLLocationDegrees longitude;
@property (readonly) CLLocationAccuracy positionalAccuracy;
@property (readonly) CLLocationCoordinate2D location;

// to-many relationships
@property RLMArray<ExploreObservationPhotoRealm *><ExploreObservationPhotoRealm> *observationPhotos;
@property RLMArray<ExploreCommentRealm *><ExploreCommentRealm> *comments;
@property RLMArray<ExploreIdentificationRealm *><ExploreIdentificationRealm> *identifications;
@property RLMArray<ExploreFaveRealm *><ExploreFaveRealm> *faves;
@property RLMArray<ExploreObsFieldValueRealm *><ExploreObsFieldValueRealm> *observationFieldValues;
@property RLMArray<ExploreProjectObservationRealm *><ExploreProjectObservationRealm> *projectObservations;

@property NSString *validationErrorMsg;
@property ExploreUserRealm *user;
@property (getter=isCaptive) BOOL captive;
@property NSString *geoprivacy;

@property BOOL ownersIdentificationFromVision;

- (RLMResults *)updatesForObservation;
- (RLMResults *)unseenUpdatesForObservation;
@property (readonly) BOOL hasUnviewedActivityBool;

+ (RLMResults *)myObservations;

- (ExploreObsFieldValueRealm *)valueForObsField:(ExploreObsFieldRealm *)field;

+ (NSDictionary *)valueForMantleModel:(ExploreObservation *)model;
+ (NSDictionary *)valueForCoreDataModel:(id)model;

- (void)setSyncedForSelfAndChildrenAt:(NSDate *)syncDate;

@end
