//
//  TaxonTests.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/2/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

@import Realm;
@import XCTest;

#import "MantleHelpers.h"
#import "ExploreObservationRealm.h"
#import "ExploreTaxonRealm.h"

@interface TaxonTests : XCTestCase
@end

@implementation TaxonTests

- (void)setUp {
    [super setUp];
    
    RLMRealm.defaultRealm.configuration.inMemoryIdentifier = @"Database A";
}

- (void)tearDown {
    [super tearDown];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm deleteAllObjects];
    [realm commitWriteTransaction];
}

- (void)testTaxonInRealmFromMantleObservation {
    ExploreObservation *willet = [MantleHelpers willetFixture];
    NSDictionary *willetDict = [ExploreObservationRealm valueForMantleModel:willet];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [ExploreObservationRealm createOrUpdateInRealm:realm withValue:willetDict];
    [realm commitWriteTransaction];
    
    // this taxon_id should be willet
    ExploreTaxonRealm *taxon = [ExploreTaxonRealm objectForPrimaryKey:@(144491)];
    XCTAssertNotNil(taxon);
}

- (void)testWikipediaUrl {
    ExploreObservation *willet = [MantleHelpers willetFixture];
    NSDictionary *willetDict = [ExploreObservationRealm valueForMantleModel:willet];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [ExploreObservationRealm createOrUpdateInRealm:realm withValue:willetDict];
    [realm commitWriteTransaction];
    
    // this taxon_id should be willet
    ExploreTaxonRealm *taxon = [ExploreTaxonRealm objectForPrimaryKey:@(144491)];
    XCTAssertTrue([[taxon wikipediaUrl] isEqual:[NSURL URLWithString:@"http://en.wikipedia.org/wiki/Willet"]],
                  @"Constructured wikipedia URL for Willet .");
}

@end
