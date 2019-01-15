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
                 @"failed to parse WilletObservationNode.json: %@",
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
    MTLModel *model = [self mtlModelFromFixture:fixturePath
                                   classMapping:[ExploreObservation class]];
    if ([model isKindOfClass:[ExploreObservation class]]) {
        return (ExploreObservation *)model;
    } else {
        return nil;
    }
}

// this needs to be an instance method to use XCTAssert and cousins
- (ExploreProject *)nodeProjectFromFixture:(NSString *)fixturePath {
    MTLModel *model = [self mtlModelFromFixture:fixturePath
                                   classMapping:[ExploreProject class]];
    if ([model isKindOfClass:[ExploreProject class]]) {
        return (ExploreProject *)model;
    } else {
        return nil;
    }
}


@end
