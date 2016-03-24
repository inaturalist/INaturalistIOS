//
//  ExploreIdentification.h
//  Explore Prototype
//
//  Created by Alex Shepard on 10/10/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "IdentificationVisualization.h"
#import "ActivityVisualization.h"

@interface ExploreIdentification : NSObject <IdentificationVisualization, ActivityVisualization>

@property (nonatomic, assign) NSInteger identificationId;
@property (nonatomic, copy) NSString *identificationBody;
@property (nonatomic, assign) BOOL identificationIsCurrent;
@property (nonatomic, copy) NSString *identificationCommonName;
@property (nonatomic, copy) NSString *identificationScientificName;
@property (nonatomic, copy) NSString *identificationPhotoUrlString;
@property (nonatomic, assign) NSInteger identificationTaxonId;
@property (nonatomic, copy) NSString *identificationTaxonRank;
@property (nonatomic, assign) NSInteger identificationTaxonRankLevel;
@property (nonatomic, copy) NSString *identificationIconicTaxonName;

@property (nonatomic, assign) NSInteger identifierId;
@property (nonatomic, copy) NSString *identifierName;
@property (nonatomic, copy) NSString *identifierIconUrl;
@property (nonatomic, copy) NSDate *identifiedDate;

@end
