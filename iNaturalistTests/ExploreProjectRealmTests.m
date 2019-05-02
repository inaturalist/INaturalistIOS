//
//  ExploreProjectRealmTests.m
//  iNaturalistTests
//
//  Created by Alex Shepard on 10/3/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Realm/Realm.h>

#import "ExploreProject.h"
#import "ExploreProjectRealm.h"
#import "MantleHelpers.h"

@interface ExploreProjectRealmTests : XCTestCase

@end

@implementation ExploreProjectRealmTests

- (void)setUp {
    [super setUp];
    
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.inMemoryIdentifier = @"TestDatabase";
    [RLMRealmConfiguration setDefaultConfiguration:config];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm deleteAllObjects];
    [realm commitWriteTransaction];
}

- (void)tearDown {
    [super tearDown];
}

- (ExploreProjectRealm *)loadTPOUA {
    ExploreProject *tpoua = [MantleHelpers tpouaProjectFixture];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    ExploreProjectRealm *epr = [[ExploreProjectRealm alloc] initWithMantleModel:tpoua];
    [realm beginWriteTransaction];
    [realm addOrUpdateObject:epr];
    [realm commitWriteTransaction];
    
    return epr;
}

- (void)loadFeaturedProjectsINat {
    NSArray *featuredProjects = [MantleHelpers featuredProjectsINat];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    for (ExploreProject *project in featuredProjects) {
        // write into realm
        ExploreProjectRealm *epr = [[ExploreProjectRealm alloc] initWithMantleModel:project];
        [realm beginWriteTransaction];
        [realm addOrUpdateObject:epr];
        [realm commitWriteTransaction];
    }
}

- (void)loadFeaturedProjectsNZ {
    NSArray *featuredProjects = [MantleHelpers featuredProjectsNZ];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    for (ExploreProject *project in featuredProjects) {
        // write into realm
        ExploreProjectRealm *epr = [[ExploreProjectRealm alloc] initWithMantleModel:project];
        [realm beginWriteTransaction];
        [realm addOrUpdateObject:epr];
        [realm commitWriteTransaction];
    }
}

- (void)loadAlexsProjects {
    NSArray *alexsProjects = [MantleHelpers alexsProjects];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    for (ExploreProject *project in alexsProjects) {
        // write into realm
        ExploreProjectRealm *epr = [[ExploreProjectRealm alloc] initWithMantleModel:project];
        [realm beginWriteTransaction];
        [realm addOrUpdateObject:epr];
        [realm commitWriteTransaction];
    }
}

- (void)testProjectFeatures {
    [self loadFeaturedProjectsINat];
    [self loadFeaturedProjectsNZ];
    [self loadAlexsProjects];
    
    RLMResults *allProjects = [ExploreProjectRealm allObjects];
    RLMResults *featuredProjectsINat = [ExploreProjectRealm featuredProjectsForSite:1];
    RLMResults *featuredProjectsNZ = [ExploreProjectRealm featuredProjectsForSite:3];

    XCTAssert(allProjects.count == 58, @"Expecting 47 total projects from fixtures");
    XCTAssert(featuredProjectsINat.count == 7, @"Expecting 6 featured projects from fixtures for site id 1");
    XCTAssert(featuredProjectsNZ.count == 13, @"Expecting 13 featured projects from fixtures for site id 1");
}


- (void)testProjectFields {
    ExploreProjectRealm *tpoua = [self loadTPOUA];
    XCTAssertEqual(tpoua.fields.count, 10);
}

- (void)testRequiredFields {
    ExploreProjectRealm *tpoua = [self loadTPOUA];
    XCTAssertEqual(tpoua.requiredFields.count, 2);
}


@end
