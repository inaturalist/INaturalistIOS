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

@interface ExploreObservationPhoto : MTLModel <INatPhoto, MTLJSONSerializing>

@property (nonatomic, readonly) NSString *mediumURL;
@property (nonatomic, readonly) NSString *squareURL;
@property (nonatomic, readonly) NSString *thumbURL;
@property (nonatomic, readonly) NSString *smallURL;
@property (nonatomic, readonly) NSString *largeURL;
@property (nonatomic, copy) NSString *url;

@end
