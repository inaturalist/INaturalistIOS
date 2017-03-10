//
//  MantleHelpers.h
//  iNaturalist
//
//  Created by Alex Shepard on 3/9/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

@class ExploreObservation;

@interface MantleHelpers : XCTestCase

// this is a simple observation, representative of most
// observations on the site. one photo, a few IDs, nothing
// else.
+ (ExploreObservation *)willetFixture;

// this is a very popular and active observation, with
// many comments, faves, photos and IDs, including some
// inactive IDs.
+ (ExploreObservation *)polychaeteFixture;

@end
