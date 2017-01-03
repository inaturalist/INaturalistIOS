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

- (void)setUp {
    [super setUp];
}

- (void)testPartnersByMCC {
    [[self allValidPartners] enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull countryCode, Partner *  _Nonnull partner, BOOL * _Nonnull stop) {
        XCTAssertTrue([[partner name] isEqualToString:[self allValidNames][countryCode]],
                      @"invalid partner name for mobile country code %@", countryCode);
    }];

}


- (void)testPartnersBaseUrl {
    [[self allValidPartners] enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull countryCode, Partner *  _Nonnull partner, BOOL * _Nonnull stop) {
        XCTAssertTrue([[partner baseURL] isEqual:[self allValidUrls][countryCode]],
                      @"invalid base url for %@ partner", countryCode);
    }];
}

- (void)testPartnersImage {
    [[self allValidPartners] enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull countryCode, Partner *  _Nonnull partner, BOOL * _Nonnull stop) {
        XCTAssertNotNil([partner logo],
                        @"invalid logo image for %@ partner", countryCode);
    }];
}

- (void)testInvalidPartner {
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
             };
}

- (NSDictionary *)allValidUrls {
    return @{
             @"302": [NSURL URLWithString:@"http://inaturalist.ca"],                    // ca
             @"530": [NSURL URLWithString:@"http://naturewatch.org.nz"],                // nz
             @"732": [NSURL URLWithString:@"http://naturalista.biodiversidad.co"],      // co
             @"334": [NSURL URLWithString:@"http://www.naturalista.mx"],                // mx
             };
}

- (NSDictionary *)allValidNames {
    return @{
             @"302": @"iNaturalist Canada",     // ca
             @"530": @"NatureWatch NZ",         // nz
             @"732": @"NaturaLista Colombia",   // co
             @"334": @"Naturalista",            // mx
             };

}

@end
