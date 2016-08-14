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
#import "Taxon.h"

@class ExploreTaxon;
@class ExploreUser;

@interface ExploreObservation : MTLModel <MKAnnotation, ObservationVisualization, Uploadable, MTLJSONSerializing>

@property (nonatomic, assign) ObsDataQuality qualityGrade;
@property (nonatomic, assign) Geoprivacy geoprivacy;
@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, assign) NSInteger observationId;
@property (nonatomic, copy) NSString *speciesGuess;
@property (nonatomic, copy) NSString *inatDescription;
@property (nonatomic, copy) NSArray *observationPhotos;
@property (nonatomic, copy) NSDate *timeObservedAt;
@property (nonatomic, copy) NSDate *observedOn;
@property (nonatomic, copy) NSDate *createdAt;
@property (nonatomic, assign) BOOL idPlease;
@property (nonatomic, assign) NSInteger identificationsCount;
@property (nonatomic, assign) NSInteger commentsCount;
@property (nonatomic, assign) NSInteger favesCount;
@property (nonatomic, copy) NSArray *identifications;
@property (nonatomic, copy) NSArray *comments;
@property (nonatomic, copy) NSArray *faves;
@property (nonatomic, assign) BOOL mappable;
@property (nonatomic, assign) NSInteger publicPositionalAccuracy;
@property (nonatomic, assign) BOOL coordinatesObscured;
@property (nonatomic, copy) NSString *placeGuess;
@property (nonatomic, assign) CLLocationCoordinate2D location;
@property (nonatomic, assign) CLLocationCoordinate2D privateLocation;
@property (readonly) CLLocationDegrees latitude;
@property (readonly) CLLocationDegrees longitude;
@property (readonly) CLLocationDegrees privateLatitude;
@property (readonly) CLLocationDegrees privateLongitude;

@property (nonatomic, readonly) BOOL hasTime;

@property (nonatomic, readonly) BOOL commentsAndIdentificationsSynchronized;

@property (nonatomic) ExploreTaxon *taxon;
@property (nonatomic) ExploreUser *user;

@end
