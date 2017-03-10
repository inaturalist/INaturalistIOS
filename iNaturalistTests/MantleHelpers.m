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

// this needs to be an instance method to use XCTAssert and cousins
- (ExploreObservation *)nodeObservationFromFixture:(NSString *)fixturePath {
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
    XCTAssertTrue(results.count == 1, @"too many results for WilletObservationNode.json");
    NSDictionary *fixtureJson = [results firstObject];
    
    NSError *mantleError = nil;
    MTLModel *result = [MTLJSONAdapter modelOfClass:[ExploreObservation class]
                                 fromJSONDictionary:fixtureJson
                                              error:&mantleError];
    XCTAssertNil(mantleError,
                 @"failed to construct Mantle object for WilletObservationNode.json: %@",
                 mantleError.localizedDescription);
    
    XCTAssertTrue([result isKindOfClass:[ExploreObservation class]],
                  @"wrong kind of Mantle object for WilletObservationNode.json.");
    
    return result;
}


@end
