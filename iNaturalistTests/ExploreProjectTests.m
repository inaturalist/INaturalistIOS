//
//  ExploreProjectTests.m
//  iNaturalistTests
//
//  Created by Alex Shepard on 12/31/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MantleHelpers.h"
#import "ExploreProject.h"

@interface ExploreProjectTests : XCTestCase

@end

@implementation ExploreProjectTests

- (void)setUp {

}

- (void)tearDown {

}

- (void)testProjectDescription {
    ExploreProject *cnc = [MantleHelpers cnc2018ProjectFixture];
    XCTAssertNotNil(cnc.description);
}

- (void)testProjectType {
    ExploreProject *cnc = [MantleHelpers cnc2018ProjectFixture];
    XCTAssertEqual(cnc.type, ExploreProjectTypeUmbrella);
    
    ExploreProject *tpoua = [MantleHelpers tpouaProjectFixture];
    XCTAssertEqual(tpoua.type, ExploreProjectTypeOldStyle);
}

- (void)testProjectFields {
    ExploreProject *tpoua = [MantleHelpers tpouaProjectFixture];
    XCTAssertEqual(tpoua.fields.count, 10);
}

- (void)testRequiredFields {
    ExploreProject *tpoua = [MantleHelpers tpouaProjectFixture];
    XCTAssertEqual(tpoua.requiredFields.count, 2);
}

@end
