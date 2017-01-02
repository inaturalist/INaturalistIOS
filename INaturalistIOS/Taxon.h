//
//  Taxon.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/21/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "INatModel.h"
#import "TaxonVisualization.h"

@interface Taxon : INatModel <TaxonVisualization>

@property (nonatomic, retain) NSNumber * recordID;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSDate * localCreatedAt;
@property (nonatomic, retain) NSDate * localUpdatedAt;
@property (nonatomic, retain) NSDate * syncedAt;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * parentID;
@property (nonatomic, retain) NSNumber * iconicTaxonID;
@property (nonatomic, retain) NSString * iconicTaxonName;
@property (nonatomic, retain) NSNumber * isIconic;
@property (nonatomic, retain) NSNumber * observationsCount;
@property (nonatomic, retain) NSNumber * listedTaxaCount;
@property (nonatomic, retain) NSNumber * rankLevel;
@property (nonatomic, retain) NSString * uniqueName;
@property (nonatomic, retain) NSString * wikipediaSummary;
@property (nonatomic, retain) NSString * wikipediaTitle;
@property (nonatomic, retain) NSString * ancestry;
@property (nonatomic, retain) NSString * conservationStatusName;
@property (nonatomic, retain) NSString * defaultName;
@property (nonatomic, retain) NSString * conservationStatusCode;
@property (nonatomic, retain) NSString * conservationStatusSourceName;
@property (nonatomic, retain) NSString * rank;
@property (nonatomic, retain) NSOrderedSet *taxonPhotos;
@property (nonatomic, retain) NSOrderedSet *listedTaxa;

+ (UIColor *)iconicTaxonColor:(NSString *)iconicTaxonName;
@end

@interface Taxon (CoreDataGeneratedAccessors)
- (void)insertObject:(NSManagedObject *)value inTaxonPhotosAtIndex:(NSUInteger)idx;
- (void)removeObjectFromTaxonPhotosAtIndex:(NSUInteger)idx;
- (void)insertTaxonPhotos:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeTaxonPhotosAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInTaxonPhotosAtIndex:(NSUInteger)idx withObject:(NSManagedObject *)value;
- (void)replaceTaxonPhotosAtIndexes:(NSIndexSet *)indexes withTaxonPhotos:(NSArray *)values;
- (void)addTaxonPhotosObject:(NSManagedObject *)value;
- (void)removeTaxonPhotosObject:(NSManagedObject *)value;
- (void)addTaxonPhotos:(NSOrderedSet *)values;
- (void)removeTaxonPhotos:(NSOrderedSet *)values;
- (NSArray *)children;
- (BOOL)isSpeciesOrLower;
- (BOOL)isGenusOrLower;
- (NSArray *)sortedTaxonPhotos;
- (BOOL)fullyLoaded;
- (NSURL *)wikipediaUrl;
@end
