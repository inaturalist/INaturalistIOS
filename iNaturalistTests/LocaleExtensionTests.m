//
//  LocaleExtensionTests.m
//  iNaturalistTests
//
//  Created by Alex Shepard on 7/14/23.
//  Copyright © 2023 iNaturalist. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NSLocale+INaturalist.h"

@interface LocaleExtensionTests : XCTestCase

@end

@implementation LocaleExtensionTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {

    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testSimplifiedChineseMainlandServerLocale {
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:@"zh-Hans_CN"];

    XCTAssertEqualObjects([locale inat_serverFormattedLocale], @"zh-CN");
}

- (void)testTraditionalChineseMacaoServerLocale {
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:@"zh-Hant_MO"];

    XCTAssertEqualObjects([locale inat_serverFormattedLocale], @"zh-MO");
}

- (void)testTraditionalChineseTaiwanServerLocale {
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:@"zh-Hant_TW"];

    XCTAssertEqualObjects([locale inat_serverFormattedLocale], @"zh-TW");
}
- (void)testTraditionalChineseHongKongServerLocale {
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:@"zh-Hant_HK"];

    XCTAssertEqualObjects([locale inat_serverFormattedLocale], @"zh-HK");
}

- (void)testSimplifiedChineseMalaysiaServerLocale {
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:@"zh-Hans_MY"];

    XCTAssertEqualObjects([locale inat_serverFormattedLocale], @"zh-CN");
}

- (void)testSimplifiedChineseSingaporeServerLocale {
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:@"zh-Hans_SG"];
    
    XCTAssertEqualObjects([locale inat_serverFormattedLocale], @"zh-CN");
}

- (void)testFrenchServerLocale {
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:@"fr_FR"];

    XCTAssertEqualObjects([locale inat_serverFormattedLocale], @"fr-FR");
}

- (void)testEnglishUSServerLocale {
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];

    XCTAssertEqualObjects([locale inat_serverFormattedLocale], @"en-US");
}

- (void)testAllLocales {
    for (NSString *localeIdentifier in [NSLocale availableLocaleIdentifiers]) {
        NSLocale *locale = [NSLocale localeWithLocaleIdentifier:localeIdentifier];

        XCTAssertNotNil([locale inat_serverFormattedLocale]);
        XCTAssertNotEqualObjects([locale inat_serverFormattedLocale], @"");
        XCTAssertFalse([[locale inat_serverFormattedLocale] containsString:@"_"]);
    }
}


@end
