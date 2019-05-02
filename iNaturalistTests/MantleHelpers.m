//
//  MantleHelpers.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/9/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import <Mantle/Mantle.h>

#import "MantleHelpers.h"
#import "ExploreObservation.h"
#import "ExploreProject.h"

@implementation MantleHelpers

+ (ExploreObservation *)willetFixture {
    NSBundle *testBundle = [NSBundle bundleForClass:self.class];
    NSString *fixturePath = [testBundle pathForResource:@"WilletObservationNode" ofType:@"json"];
    
    MantleHelpers *helper = [[MantleHelpers alloc] init];
    return [helper nodeObservationFromFixture:fixturePath];
}

+ (ExploreObservation *)polychaeteFixture {
    NSBundle *testBundle = [NSBundle bundleForClass:self.class];
    NSString *fixturePath = [testBundle pathForResource:@"PolychaeteObservationNode" ofType:@"json"];
    
    MantleHelpers *helper = [[MantleHelpers alloc] init];
    return [helper nodeObservationFromFixture:fixturePath];
}

+ (NSArray *)alexsProjects {
    NSBundle *testBundle = [NSBundle bundleForClass:self.class];
    NSString *fixturePath = [testBundle pathForResource:@"AlexsProjects" ofType:@"json"];
    
    MantleHelpers *helper = [[MantleHelpers alloc] init];
    return [helper nodeProjectsFromFixture:fixturePath];
}

+ (NSArray *)featuredProjectsINat {
    NSBundle *testBundle = [NSBundle bundleForClass:self.class];
    NSString *fixturePath = [testBundle pathForResource:@"FeaturedProjectsINat" ofType:@"json"];
    
    
    MantleHelpers *helper = [[MantleHelpers alloc] init];
    return [helper nodeProjectsFromFixture:fixturePath];
}

+ (NSArray *)featuredProjectsNZ {
    NSBundle *testBundle = [NSBundle bundleForClass:self.class];
    NSString *fixturePath = [testBundle pathForResource:@"FeaturedProjectsNZ" ofType:@"json"];
    
    
    MantleHelpers *helper = [[MantleHelpers alloc] init];
    return [helper nodeProjectsFromFixture:fixturePath];
}


+ (ExploreProject *)cnc2018ProjectFixture {
    NSBundle *testBundle = [NSBundle bundleForClass:self.class];
    NSString *fixturePath = [testBundle pathForResource:@"cnc2018ProjectNode" ofType:@"json"];
    
    MantleHelpers *helper = [[MantleHelpers alloc] init];
    return [helper nodeProjectFromFixture:fixturePath];
}

+ (ExploreProject *)tpouaProjectFixture {
    NSBundle *testBundle = [NSBundle bundleForClass:self.class];
    NSString *fixturePath = [testBundle pathForResource:@"tpouaProjectNode" ofType:@"json"];
    
    MantleHelpers *helper = [[MantleHelpers alloc] init];
    return [helper nodeProjectFromFixture:fixturePath];
}

// this needs to be an instance method to use XCTAssert and cousins
- (MTLModel *)mtlModelFromFixture:(NSString *)fixturePath classMapping:(Class)classForMapping {
    NSData *fixtureData = [NSData dataWithContentsOfFile:fixturePath];
    NSError *deserializeError = nil;
    id json = [NSJSONSerialization JSONObjectWithData:fixtureData
                                              options:kNilOptions
                                                error:&deserializeError];
    
    XCTAssertNil(deserializeError,
                 @"failed to parse fixture: %@",
                 deserializeError.localizedDescription);
    NSLog(@"JSON: %@", json);
    
    NSArray *results = [json valueForKey:@"results"];
    XCTAssertTrue(results.count == 1, @"too many results for fixture %@", fixturePath);
    NSDictionary *fixtureJson = [results firstObject];
    
    NSError *mantleError = nil;
    MTLModel *result = [MTLJSONAdapter modelOfClass:classForMapping
                                 fromJSONDictionary:fixtureJson
                                              error:&mantleError];
   
    XCTAssertNil(mantleError, @"error constructing Mantle object for %@: %@",
                 fixturePath, mantleError.localizedDescription);
    
    XCTAssertNotNil(result, @"failed to construct Mantle object for %@",
                    fixturePath);

    XCTAssertTrue([result isKindOfClass:classForMapping],
                  @"wrong kind of Mantle object for fixture %@, expected %@ but got %@",
                  fixturePath,
                  NSStringFromClass(classForMapping),
                  NSStringFromClass([result class])
                  );
    
    return result;
}

// this needs to be an instance method to use XCTAssert and cousins
- (ExploreObservation *)nodeObservationFromFixture:(NSString *)fixturePath {
    return (ExploreObservation *)[self mtlModelFromFixture:fixturePath
                                              classMapping:[ExploreObservation class]];
}

// this needs to be an instance method to use XCTAssert and cousins
- (ExploreProject *)nodeProjectFromFixture:(NSString *)fixturePath {
    return (ExploreProject *)[self mtlModelFromFixture:fixturePath
                                          classMapping:[ExploreProject class]];
}

// this needs to be an instance method to use XCTAssert and cousins
- (NSArray *)nodeProjectsFromFixture:(NSString *)fixturePath {
    return [self multipleMtlModelsFromFixture:fixturePath
                                 classMapping:[ExploreProject class]];
}

- (NSArray *)multipleMtlModelsFromFixture:(NSString *)fixturePath classMapping:(Class)classForMapping {
    NSData *fixtureData = [NSData dataWithContentsOfFile:fixturePath];
    NSError *deserializeError = nil;
    id json = [NSJSONSerialization JSONObjectWithData:fixtureData
                                              options:kNilOptions
                                                error:&deserializeError];
    
    XCTAssertNil(deserializeError,
                 @"failed to parse fixture: %@",
                 deserializeError.localizedDescription);
    NSLog(@"JSON: %@", json);
    
    NSArray *jsonResults = [json valueForKey:@"results"];
    NSMutableArray *mtlResults = [NSMutableArray arrayWithCapacity:jsonResults.count];
    for (NSDictionary *fixtureJson in jsonResults) {
        NSError *mantleError = nil;
        MTLModel *mtlResult = [MTLJSONAdapter modelOfClass:classForMapping
                                        fromJSONDictionary:fixtureJson
                                                     error:&mantleError];
        
        XCTAssertNil(mantleError, @"error constructing Mantle object for %@: %@",
                     fixturePath, mantleError.localizedDescription);
        
        XCTAssertNotNil(mtlResult, @"failed to construct Mantle object for %@",
                        fixturePath);
        
        XCTAssertTrue([mtlResult isKindOfClass:classForMapping],
                      @"wrong kind of Mantle object for fixture %@, expected %@ but got %@",
                      fixturePath,
                      NSStringFromClass(classForMapping),
                      NSStringFromClass([mtlResult class])
                      );
        
        [mtlResults addObject:mtlResult];
    }
    
    return mtlResults;
}

@end
