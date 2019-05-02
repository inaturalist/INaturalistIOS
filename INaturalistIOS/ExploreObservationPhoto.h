//
//  ExploreObservationPhoto.h
//  Explore Prototype
//
//  Created by Alex Shepard on 9/9/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

#import "INatPhoto.h"

@interface ExploreObservationPhoto : MTLModel <MTLJSONSerializing, INatPhoto>

@property (nonatomic, assign) NSInteger observationPhotoId;
@property (nonatomic, assign) NSInteger position;
@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, copy) NSString *licenseCode;
@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) NSString *attribution;

@end
