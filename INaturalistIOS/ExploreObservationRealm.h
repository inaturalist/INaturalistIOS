//
//  ExploreObservationRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 1/12/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>

#import "ExploreObservation.h"
#import "ObservationVisualization.h"
#import "Uploadable.h"
#import "ExploreTaxonRealm.h"
#import "ExploreUserRealm.h"
#import "ExploreCommentRealm.h"
#import "ExploreIdentificationRealm.h"
#import "ExploreObservationFieldValueRealm.h"
#import "ExploreObservationPhotoRealm.h"
#import "ExploreFaveRealm.h"

@interface ExploreObservationRealm : RLMObject <ObservationVisualization, Uploadable>

@property NSInteger observationId;
@property NSString *speciesGuess;
@property NSString *inatDescription;
@property NSDate *timeObservedAt;
@property NSDate *observedOn;
@property NSString *qualityGrade;
@property NSInteger identificationsCount;
@property NSInteger commentsCount;
@property BOOL mappable;
@property NSInteger publicPositionalAccuracy;
@property BOOL coordinatesObscured;
@property NSString *placeGuess;
@property NSString *validationErrorMsg;
@property NSString *geoprivacy;
@property BOOL captive;

@property CLLocationDegrees latitude;
@property CLLocationDegrees longitude;
@property NSString *uuid;

@property RLMArray <ExploreCommentRealm *><ExploreCommentRealm> *comments;
@property RLMArray <ExploreIdentificationRealm *><ExploreIdentificationRealm> *identifications;
@property RLMArray <ExploreObservationFieldValueRealm *><ExploreObservationFieldValueRealm> *observationFieldValues;
@property RLMArray <ExploreObservationPhotoRealm *><ExploreObservationPhotoRealm> *observationPhotos;
@property RLMArray <ExploreFaveRealm *><ExploreFaveRealm> *faves;
// TODO: project observatio

@property ExploreTaxonRealm *taxon;
@property ExploreUserRealm *user;

@property NSDate *syncedAt;

@property (readonly) CLLocationCoordinate2D location;
@property (readonly) BOOL hasTime;
@property (readonly) BOOL commentsAndIdentificationsSynchronized;

- (instancetype)initWithMantleModel:(ExploreObservation *)model;

@end
