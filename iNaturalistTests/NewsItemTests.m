//
//  NewsItemTests.m
//  iNaturalist
//
//  Created by Alex Shepard on 12/16/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

@import Realm;
@import XCTest;

#import "ExplorePost.h"
#import "MantleHelpers.h"

@interface NewsItemTests : XCTestCase

@end

@implementation NewsItemTests

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

- (void)testProjectBlogUrlConstruction {
    ExplorePost *projectPost = [MantleHelpers projectPostFixture];
    XCTAssertTrue([[projectPost urlForNewsItem] isEqual:[NSURL URLWithString:@"https://www.inaturalist.org/projects/5813/journal/29357"]],
                   @"Constructed URL for project post is incorrect.");
}

- (void)testSiteNewsUrlConstruction {
    ExplorePost *sitePost = [MantleHelpers sitePostFixture];
    XCTAssertTrue([[sitePost urlForNewsItem] isEqual:[NSURL URLWithString:@"https://www.inaturalist.org/blog/30519"]],
                   @"Constructed URL for site post is incorrect.");
}


@end

