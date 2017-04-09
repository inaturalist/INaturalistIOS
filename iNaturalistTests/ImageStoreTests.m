//
//  ImageStoreTests.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/10/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ImageStore.h"

@interface ImageStoreTests : XCTestCase

@end

@implementation ImageStoreTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testCutdown {
    ImageStore *is = [ImageStore sharedImageStore];
    NSString *baseKey = [is createKey];
    UIImage *willet = [self willetImage];
    
    XCTAssertNotNil(willet, @"willet fixture image can't be nil");
    
    NSError *storeError = nil;
    [is storeImage:willet forKey:baseKey error:&storeError];
    XCTAssertNil(storeError,
                 @"failed to store fixture image: %@",
                 storeError.localizedDescription);
    
    UIImage *square = [is find:baseKey forSize:ImageStoreSquareSize];
    XCTAssertNotNil(square, @"failed to load square size for willet size");
    XCTAssertTrue(CGSizeEqualToSize(square.size, CGSizeMake(128, 128)),
                  @"wrong size for square size of willet fixture");
    
    UIImage *small = [is find:baseKey forSize:ImageStoreSmallSize];
    XCTAssertNotNil(small, @"failed to load small size for willet size");
}

- (void)testPathVsFind {
    ImageStore *is = [ImageStore sharedImageStore];
    NSString *baseKey = [is createKey];
    UIImage *willet = [self willetImage];
    
    XCTAssertNotNil(willet, @"willet fixture image can't be nil");
    
    NSError *storeError = nil;
    [is storeImage:willet forKey:baseKey error:&storeError];
    XCTAssertNil(storeError,
                 @"failed to store fixture image: %@",
                 storeError.localizedDescription);
    
    UIImage *squareViaFind = [is find:baseKey forSize:ImageStoreSquareSize];
    XCTAssertNotNil(squareViaFind, @"square via find doesn't exist");

    // need to wait for the cutdown to flush to disk. frustrating
    // how long this wait is, but shorter waits don't seem to work,
    // and i haven't found a way to force SDWebImage to process its
    // ioQueue.
    NSDate *runUntil = [NSDate dateWithTimeIntervalSinceNow: 10.0];
    [[NSRunLoop currentRunLoop] runUntilDate:runUntil];

    NSString *squarePath = [is pathForKey:baseKey forSize:ImageStoreSquareSize];
    UIImage *squareViaPath = [UIImage imageWithContentsOfFile:squarePath];

    XCTAssertNotNil(squareViaPath, @"square via path doesn't exist");
    
    // can't test equality because while most of the bytes are the same,
    // SDWebImage returns a slightly different image from find vs what is
    // on the disk. why? no idea.
}

- (UIImage *)willetImage {
    NSBundle *testBundle = [NSBundle bundleForClass:self.class];
    NSString *fixturePath = [testBundle pathForResource:@"willet" ofType:@"jpg"];
    return [self imageFromFixture:fixturePath];
}

- (UIImage *)imageFromFixture:(NSString *)fixturePath {
    return [UIImage imageWithContentsOfFile:fixturePath];
}

@end
