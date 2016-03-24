//
//  ExploreObservationPhoto.h
//  Explore Prototype
//
//  Created by Alex Shepard on 9/9/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "INatPhoto.h"

@interface ExploreObservationPhoto : NSObject <INatPhoto>

@property (nonatomic, copy) NSString *mediumURL;
@property (nonatomic, copy) NSString *squareURL;
@property (nonatomic, copy) NSString *thumbURL;
@property (nonatomic, copy) NSString *smallURL;
@property (nonatomic, copy) NSString *largeURL;
@property (nonatomic, copy) NSString *url;

@end
