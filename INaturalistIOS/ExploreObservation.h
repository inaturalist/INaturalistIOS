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

@interface ExploreObservation : MTLModel <MKAnnotation, ObservationVisualization, Uploadable, MTLJSONSerializing>

@property (nonatomic, assign) NSInteger observationId;
@property (nonatomic, copy) NSString *speciesGuess;
@property (nonatomic, copy) NSString *inatDescription;
@property (nonatomic, copy) NSDate *timeObservedAt;
@property (nonatomic, copy) NSDate *observedOn;
@property (nonatomic, copy) NSString *qualityGrade;
@property (nonatomic, assign) NSInteger identificationsCount;
@property (nonatomic, assign) NSInteger commentsCount;
@property (nonatomic, assign) BOOL mappable;
@property (nonatomic, assign) NSInteger publicPositionalAccuracy;
@property (nonatomic, assign) BOOL coordinatesObscured;
@property (nonatomic, copy) NSString *placeGuess;
@property (nonatomic, assign) CLLocationCoordinate2D location;
@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, copy) NSString *geoprivacy;
@property (nonatomic, assign) BOOL captive;

@property (nonatomic, copy) NSArray *observationPhotos;
@property (nonatomic, copy) NSArray *identifications;
@property (nonatomic, copy) NSArray *comments;
@property (nonatomic, copy) NSArray *faves;
@property (nonatomic, copy) NSArray *observationFieldValues;

@property (nonatomic) ExploreTaxon *taxon;
@property (nonatomic) ExploreUser *user;

@property (nonatomic, readonly) BOOL hasTime;
@property (nonatomic, readonly) BOOL commentsAndIdentificationsSynchronized;
@property (readonly) CLLocationDegrees latitude;
@property (readonly) CLLocationDegrees longitude;

@end
