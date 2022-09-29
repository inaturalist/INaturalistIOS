//
//  PartnerTests.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/2/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "PartnerController.h"
#import "Partner.h"

@interface PartnerTests : XCTestCase
@end

@implementation PartnerTests

- (void)testPartnerNamesByMCC {
    [[self allValidPartners] enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull countryCode, Partner *  _Nonnull partner, BOOL * _Nonnull stop) {
        XCTAssertTrue([[partner name] isEqualToString:[self allValidNames][countryCode]],
                      @"invalid partner name for mobile country code %@", countryCode);
    }];
}

- (void)testPartnerShortNameByMCC {
    [[self allValidPartners] enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull countryCode, Partner *  _Nonnull partner, BOOL * _Nonnull stop) {
        XCTAssertTrue([[partner shortName] isEqualToString:[self allValidShortNames][countryCode]],
                      @"invalid partner short for mobile country code %@", countryCode);
    }];
}


- (void)testPartnersBaseUrlByMCC {
    [[self allValidPartners] enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull countryCode, Partner *  _Nonnull partner, BOOL * _Nonnull stop) {
        XCTAssertTrue([[partner baseURL] isEqual:[self allValidUrls][countryCode]],
                      @"invalid base url for %@ partner", countryCode);
    }];
}

- (void)testPartnersImageByMCC {
    [[self allValidPartners] enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull countryCode, Partner *  _Nonnull partner, BOOL * _Nonnull stop) {
        XCTAssertNotNil([partner logo],
                        @"invalid logo image for %@ partner", countryCode);
    }];
}

- (void)testInvalidPartnerByMCC {
    PartnerController *pc = [[PartnerController alloc] init];

    XCTAssertNil([pc partnerForMobileCountryCode:@"-199"],
                 @"-199 should generate nil partner");
}

- (NSDictionary *)allValidPartners {
    PartnerController *pc = [[PartnerController alloc] init];

    return @{
             @"302": [pc partnerForMobileCountryCode:@"302"],   // ca
             @"530": [pc partnerForMobileCountryCode:@"530"],   // nz
             @"732": [pc partnerForMobileCountryCode:@"732"],   // co
             @"334": [pc partnerForMobileCountryCode:@"334"],   // mx
             @"268": [pc partnerForMobileCountryCode:@"268"],   // pt
             };
}

- (NSDictionary *)allValidUrls {
    return @{
             @"302": [NSURL URLWithString:@"https://inaturalist.ca"],                    // ca
             @"530": [NSURL URLWithString:@"https://inaturalist.nz"],                // nz
             @"732": [NSURL URLWithString:@"https://colombia.inaturalist.org"],      // co
             @"334": [NSURL URLWithString:@"https://www.naturalista.mx"],                // mx
             @"268": [NSURL URLWithString:@"https://www.biodiversity4all.org"],         // pt
             };
}

- (NSDictionary *)allValidNames {
    return @{
             @"302": @"iNaturalist Canada",     // ca
             @"530": @"iNaturalist NZ – Mātaki Taiao",         // nz
             @"732": @"NaturaLista Colombia",   // co
             @"334": @"Naturalista",            // mx
             @"268": @"Biodiversity4All",       // pt
             };
}

- (NSDictionary *)allValidShortNames {
    return @{
             @"302": @"iNaturalist Canada",     // ca
             @"530": @"iNaturalist NZ",         // nz
             @"732": @"NaturaLista Colombia",   // co
             @"334": @"Naturalista",            // mx
             @"268": @"Biodiversity4All",       // pt
             };
}

@end
