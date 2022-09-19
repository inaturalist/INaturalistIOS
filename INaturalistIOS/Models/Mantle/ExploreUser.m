//
//  ExploreUser.m
//  iNaturalist
//
//  Created by Alex Shepard on 6/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ExploreUser.h"

@implementation ExploreUser

+ (NSDictionary *)JSONKeyPathsByPropertyKey{
    return @{
             @"userId": @"id",
             @"login": @"login",
             @"name": @"name",
             @"userIcon": @"icon",
             @"email": @"email",
             @"observationsCount": @"observations_count",
             @"siteId": @"site_id",
             @"prefersNoTracking": @"prefers_no_tracking",
             @"showCommonNames": @"prefers_common_names",
             @"showScientificNamesFirst": @"prefers_scientific_name_first",
             @"piConsent": @"pi_consent",
             @"dataTransferConsent": @"data_transfer_consent",
             };
}

+ (NSValueTransformer *)userIconJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

- (NSURL *)userIconMedium {
    NSString *thumbUrlString = [[self userIcon] absoluteString];
    NSString *mediumUrlString = [thumbUrlString stringByReplacingOccurrencesOfString:@"thumb"
                                                                          withString:@"medium"];
    return [NSURL URLWithString:mediumUrlString];
}

- (void)setNilValueForKey:(NSString *)key {
    if ([key isEqualToString:@"siteId"]) {
        // inaturalist site
        self.siteId = 1;
    } else if ([key isEqualToString:@"prefersNoTracking"]) {
        self.prefersNoTracking = FALSE;
    } else if ([key isEqualToString:@"showCommonNames"]) {
        self.showCommonNames = FALSE;
    } else if ([key isEqualToString:@"showScientificNamesFirst"]) {
        self.showScientificNamesFirst = FALSE;
    } else if ([key isEqualToString:@"piConsent"]) {
        self.piConsent = FALSE;
    } else if ([key isEqualToString:@"dataTransferConsent"]) {
        self.dataTransferConsent = FALSE;
    } else {
        [super setNilValueForKey:key];
    }

}

@end
