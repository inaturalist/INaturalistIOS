//
//  ExploreObservationTests.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/9/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MantleHelpers.h"
#import "ExploreObservation.h"

@interface ExploreObservationTests : XCTestCase
@end

@implementation ExploreObservationTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}


- (void)testRelationships {
    ExploreObservation *willet = [MantleHelpers willetFixture];
    
    XCTAssertEqual(willet.comments.count, 0, @"wrong number of comments for willet fixture");
    XCTAssertEqual(willet.identifications.count, 2, @"wrote number of ids for willet fixture");
    XCTAssertEqual(willet.faves.count, 0, @"wrong number of faves for willet fixture");
    XCTAssertEqual(willet.observationPhotos.count, 1, @"wrong number of photos for willet fixture");
    XCTAssertEqualObjects(willet.username, @"alexshepard", @"wrong observer for willet fixture");
    
    ExploreObservation *polychaete = [MantleHelpers polychaeteFixture];
    
    XCTAssertEqual(polychaete.comments.count, 9, @"wrong number of comments for polychaete fixture");
    XCTAssertEqual(polychaete.identifications.count, 8, @"wrote number of ids for polychaete fixture");
    XCTAssertEqual(polychaete.faves.count, 5, @"wrong number of faves for polychaete fixture");
    XCTAssertEqual(polychaete.observationPhotos.count, 22, @"wrong number of photos for polychaete fixture");
    XCTAssertEqualObjects(polychaete.username, @"raulagrait", @"wrong observer for polychaete fixture");

}


@end
