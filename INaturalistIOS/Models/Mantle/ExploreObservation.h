//
//  ExploreObservation.h
//  Explore Prototype
//
//  Created by Alex Shepard on 9/9/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <Mantle/Mantle.h>

#import "ObservationVisualization.h"
#import "Uploadable.h"

@class ExploreTaxon;
@class ExploreUser;

@interface ExploreObservation : MTLModel <MKAnnotation, ObservationVisualization, MTLJSONSerializing>

@property (nonatomic, assign) NSInteger observationId;
@property (nonatomic, copy) NSString *speciesGuess;
@property (nonatomic, copy) NSString *inatDescription;
@property (nonatomic, copy) NSArray *observationPhotos;
@property (nonatomic, copy) NSArray *observationSounds;
@property (nonatomic, readonly) NSArray *observationMedia;
// both time and date for observations with both
@property (nonatomic, copy) NSDate *timeObserved;
// for observations with a date but without a time
@property (nonatomic, copy) NSString *observedTimeZone;
@property (nonatomic, copy) NSDate *dateObserved;
@property (nonatomic, copy) NSDate *timeCreated;
@property (nonatomic, assign) ObsDataQuality dataQuality;
@property (nonatomic, assign) NSInteger identificationsCount;
@property (nonatomic, assign) NSInteger commentsCount;
@property (nonatomic, copy) NSArray *identifications;
@property (nonatomic, copy) NSArray *comments;
@property (nonatomic, copy) NSArray *faves;
@property (nonatomic, copy) NSArray *projectObservations;
@property (nonatomic, copy) NSArray *observationFieldValues;
@property (nonatomic, assign) BOOL mappable;
@property (nonatomic, copy) NSString *placeGuess;
@property (nonatomic, assign, getter=isCaptive) BOOL captive;
@property (nonatomic, copy) NSString *geoprivacy;
@property (nonatomic, assign) BOOL ownersIdentificationFromVision;

@property (nonatomic, assign) CLLocationCoordinate2D location;
@property (nonatomic, assign) CLLocationCoordinate2D privateLocation;

@property (nonatomic, assign) CLLocationAccuracy publicPositionalAccuracy;
@property (nonatomic, assign) CLLocationAccuracy privatePositionalAccuracy;
@property (readonly) CLLocationAccuracy positionalAccuracy;

@property (nonatomic, assign) BOOL coordinatesObscured;

@property (readonly) CLLocationDegrees latitude;
@property (readonly) CLLocationDegrees longitude;

@property (nonatomic, copy) NSString *uuid;

@property (nonatomic, readonly) BOOL commentsAndIdentificationsSynchronized;

@property (nonatomic) ExploreTaxon *taxon;
@property (nonatomic) ExploreUser *user;

@end
