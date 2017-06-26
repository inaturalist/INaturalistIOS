//
//  Observation.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/15/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "INatModel.h"
#import "Uploadable.h"
#import "ObservationVisualization.h"

#define INatUserSavedObservationNotification @"INatObservationsNeedSyncNotification"

@class Taxon, Comment, Identification;

@interface Observation : INatModel <Uploadable, ObservationVisualization>

@property (nonatomic, retain) NSString * speciesGuess;
@property (nonatomic, retain) NSNumber * taxonID;
@property (nonatomic, retain) NSString * inatDescription;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * positionalAccuracy;
@property (nonatomic, retain) NSDate * observedOn;
@property (nonatomic, retain) NSDate * localObservedOn;
@property (nonatomic, retain) NSString * observedOnString;
@property (nonatomic, retain) NSDate * timeObservedAt;
@property (nonatomic, retain) NSNumber * userID;
@property (nonatomic, retain) NSString * placeGuess;
@property (nonatomic, retain) NSNumber * idPlease;
@property (nonatomic, retain) NSNumber * iconicTaxonID;
@property (nonatomic, retain) NSString * iconicTaxonName;
@property (nonatomic, retain) NSNumber * privateLatitude;
@property (nonatomic, retain) NSNumber * privateLongitude;
@property (nonatomic, retain) NSNumber * privatePositionalAccuracy;
@property (nonatomic, retain) NSString * geoprivacy;
@property (nonatomic, retain) NSString * qualityGrade;
@property (nonatomic, retain) NSString * positioningMethod;
@property (nonatomic, retain) NSString * positioningDevice;
@property (nonatomic, retain) NSNumber * outOfRange;
@property (nonatomic, retain) NSString * license;
@property (nonatomic, retain) NSSet * observationPhotos;
@property (nonatomic, retain) NSSet * observationFieldValues;
@property (nonatomic, retain) NSSet * projectObservations;
@property (nonatomic, retain) NSNumber * commentsCount;
@property (nonatomic, retain) NSNumber * identificationsCount;
@property (nonatomic, retain) NSNumber * hasUnviewedActivity;
@property (nonatomic, retain) Taxon *taxon;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) NSSet *identifications;
@property (nonatomic, retain) NSString *sortable;
@property (nonatomic, retain) NSString *uuid;
@property (nonatomic, retain) NSString *validationErrorMsg;
@property (nonatomic, retain) NSNumber *captive;
@property (nonatomic, retain) NSSet *faves;
@property (nonatomic, retain) NSNumber *favesCount;
@property (nonatomic, retain) NSNumber *ownersIdentificationFromVision;

- (NSString *)observedOnPrettyString;
- (NSString *)observedOnShortString;
- (UIColor *)iconicTaxonColor;
- (NSArray *)sortedObservationPhotos;
- (NSArray *)sortedProjectObservations;
- (NSArray *)sortedFaves;
- (NSArray *)sortedActivity;
- (NSNumber *)visibleLatitude;
- (NSNumber *)visibleLongitude;
- (NSInteger)activityCount;
- (Observation *)prevObservation;
- (Observation *)nextObservation;
+ (NSFetchRequest *)defaultAscendingSortedFetchRequest;
+ (NSFetchRequest *)defaultDescendingSortedFetchRequest;

- (NSString *)presentableGeoprivacy;
- (ObsDataQuality)dataQuality;

@end

@interface Observation (PrimitiveAccessors)
- (NSNumber *)primitiveTaxonID;
- (void)setPrimitiveTaxonID:(NSNumber *)newTaxonId;
- (NSNumber *)primitiveIconicTaxonName;
- (void)setPrimitiveIconicTaxonName:(NSNumber *)newIconicTaxonName;
@end

@interface Observation (CoreDataGeneratedAccessors)
- (void)insertObject:(NSManagedObject *)value inProjectObservationsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromProjectObservationsAtIndex:(NSUInteger)idx;

- (void)insertProjectObservations:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeProjectObservationsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInProjectObservationsAtIndex:(NSUInteger)idx withObject:(NSManagedObject *)value;
- (void)replaceProjectObservationsAtIndexes:(NSIndexSet *)indexes withProjectObservations:(NSArray *)values;
- (void)addProjectObservationsObject:(NSManagedObject *)value;
- (void)removeProjectObservationsObject:(NSManagedObject *)value;
- (void)addProjectObservations:(NSSet *)values;
- (void)removeProjectObservations:(NSSet *)values;

- (void)insertObservationFieldValues:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeObservationFieldValuesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInObservationFieldValuesAtIndex:(NSUInteger)idx withObject:(NSManagedObject *)value;
- (void)replaceObservationFieldValuesAtIndexes:(NSIndexSet *)indexes withProjectObservations:(NSArray *)values;
- (void)addObservationFieldValuesObject:(NSManagedObject *)value;
- (void)removeObservationFieldValuesObject:(NSManagedObject *)value;
- (void)addObservationFieldValue:(NSSet *)values;
- (void)removeObservationFieldValue:(NSSet *)values;
@end

