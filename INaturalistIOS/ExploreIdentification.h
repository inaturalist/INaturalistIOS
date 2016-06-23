//
//  ExploreIdentification.h
//  Explore Prototype
//
//  Created by Alex Shepard on 10/10/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

#import "IdentificationVisualization.h"
#import "ActivityVisualization.h"

@class ExploreUser;
@class ExploreTaxon;

@interface ExploreIdentification : MTLModel <IdentificationVisualization, ActivityVisualization, MTLJSONSerializing>

@property (nonatomic, assign) NSInteger identificationId;
@property (nonatomic, copy) NSString *identificationBody;
@property (nonatomic, assign) BOOL identificationIsCurrent;
@property (nonatomic, retain) NSDate *identifiedDate;

@property (nonatomic, retain) ExploreUser *identifier;
@property (nonatomic, retain) ExploreTaxon *taxon;

@end
