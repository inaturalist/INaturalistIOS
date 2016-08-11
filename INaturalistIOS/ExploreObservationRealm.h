//
//  ExploreObservationRealm.h
//  iNaturalist
//
//  Created by Alex Shepard on 8/9/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>
#import <CoreLocation/CoreLocation.h>

#import "ExploreObservation.h"
#import "ExploreObservationPhotoRealm.h"
#import "ExploreTaxonRealm.h"
#import "ExploreUserRealm.h"
#import "ExploreIdentificationRealm.h"
#import "ExploreCommentRealm.h"
#import "ExploreFaveRealm.h"

@interface ExploreObservationRealm : RLMObject <ObservationVisualization>

@property ObsDataQuality qualityGrade;
@property Geoprivacy geoprivacy;
@property NSString *uuid;
@property NSInteger observationId;
@property NSString *speciesGuess;
@property NSString *inatDescription;
@property NSDate *timeObservedAt;
@property NSDate *observedOn;
@property NSDate *createdAt;
@property BOOL idPlease;
@property NSInteger identificationsCount;
@property NSInteger commentsCount;
@property NSInteger favesCount;
@property BOOL mappable;
@property NSInteger publicPositionalAccuracy;
@property BOOL coordinatesObscured;
@property NSString *placeGuess;
@property BOOL hasUnviewedActivity;
@property (readonly) CLLocationCoordinate2D location;
@property CLLocationDegrees latitude;
@property CLLocationDegrees longitude;
@property NSString *validationErrorMsg;

@property (readonly) BOOL hasTime;

// basically, do our comment/id/fave counts match up
@property (readonly) BOOL fullySynchronized;

@property (readonly) BOOL needsUpload;

// to-one relationships
@property ExploreTaxonRealm *taxon;
@property ExploreUserRealm *user;

// to-many relationships
@property RLMArray<ExploreObservationPhotoRealm *><ExploreObservationPhotoRealm> *observationPhotos;
@property RLMArray <ExploreIdentificationRealm *><ExploreIdentificationRealm> *identifications;
@property RLMArray <ExploreCommentRealm *><ExploreCommentRealm> *comments;
@property RLMArray <ExploreFaveRealm *><ExploreFaveRealm> *faves;

- (instancetype)initWithMantleModel:(ExploreObservation *)model;

@end
