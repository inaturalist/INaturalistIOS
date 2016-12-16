//
//  NewsItemTests.m
//  iNaturalist
//
//  Created by Alex Shepard on 12/16/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RestKit/Testing.h>

#import "NewsItem.h"

@interface NewsItemTests : XCTestCase
@property RKManagedObjectStore *objectStore;
@end

@implementation NewsItemTests

- (void)setUp {
    [super setUp];

    NSBundle *testTargetBundle = [NSBundle bundleForClass:self.class];
    [RKTestFixture setFixtureBundle:testTargetBundle];
    [RKTestFactory setUp];
        
    [RKTestFactory defineFactory:RKTestFactoryDefaultNamesManagedObjectStore withBlock:^id{
        NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:@[[NSBundle mainBundle]]];
        RKManagedObjectStore *managedObjectStore = [RKManagedObjectStore objectStoreWithStoreFilename:@"inaturalistTests.sqlite"
                                                                                usingSeedDatabaseName:nil
                                                                                   managedObjectModel:managedObjectModel
                                                                                             delegate:nil];
        return managedObjectStore;
    }];
    self.objectStore = [RKTestFactory managedObjectStore];
}

- (void)tearDown {
    [super tearDown];
    [RKTestFactory tearDown];
}

- (void)testProjectBlogUrlConstruction {
    id parsedJSON = [RKTestFixture parsedObjectWithContentsOfFixture:@"ProjectBlogPost.json"];
    
    NewsItem *newsItem = [NewsItem createEntity];
    
    RKMappingTest *test = [RKMappingTest testForMapping:[NewsItem mapping]
                                           sourceObject:parsedJSON
                                      destinationObject:newsItem];

    [test performMapping];
    XCTAssertTrue([[newsItem urlForNewsItem] isEqual:[NSURL URLWithString:@"https://www.inaturalist.org/projects/5813/journal/7699"]],
                   @"Constructed URL for project post is incorrect.");
}

- (void)testSiteNewsUrlConstruction {
    id parsedJSON = [RKTestFixture parsedObjectWithContentsOfFixture:@"SiteBlogPost.json"];
    
    NewsItem *newsItem = [NewsItem createEntity];
    
    RKMappingTest *test = [RKMappingTest testForMapping:[NewsItem mapping]
                                           sourceObject:parsedJSON
                                      destinationObject:newsItem];
    
    [test performMapping];
    XCTAssertTrue([[newsItem urlForNewsItem] isEqual:[NSURL URLWithString:@"https://www.inaturalist.org/blog/8014"]],
                  @"Constructed URL for site news post is incorrect.");
}


@end
