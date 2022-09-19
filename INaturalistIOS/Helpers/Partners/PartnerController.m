//
//  PartnerController.m
//  iNaturalist
//
//  Created by Alex Shepard on 6/16/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import "PartnerController.h"
#import "Partner.h"

@implementation PartnerController

- (instancetype)init {
    if (self = [super init]) {
        self.partners = [NSArray array];
        
        // would be great to move this into core data, backed by inaturalist.org
        NSString *path = [[NSBundle mainBundle] pathForResource:@"partners" ofType:@"plist"];
        NSArray *partners = [NSArray arrayWithContentsOfFile:path];
        NSMutableArray *mutablePartners = [NSMutableArray array];
        for (NSDictionary *partnerDict in partners) {
            Partner *partner = [[Partner alloc] initWithDictionary:partnerDict];
            // initializer can return nil in the event of an invalid or badly formatted plist
            if (partner) {
                [mutablePartners addObject:partner];
            }
        }
        
        [mutablePartners sortUsingComparator:^NSComparisonResult(Partner *p1, Partner *p2) {
            return p1.identifier > p2.identifier;

        }];
        
        self.partners = [NSArray arrayWithArray:mutablePartners];
    }
    
    return self;
}

- (Partner *)partnerForMobileCountryCode:(NSString *)mobileCountryCode {
    for (Partner *p in self.partners) {
        if ([p.mobileCountryCodes containsObject:mobileCountryCode]) {
            return p;
        }
    }
    return nil;
}

- (Partner *)partnerForSiteId:(NSInteger)siteId {
    for (Partner *p in self.partners) {
        if (p.identifier == siteId) {
            return p;
        }
    }
    
    return self.partners[0];
}

@end
