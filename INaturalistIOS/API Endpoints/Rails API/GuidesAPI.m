//
//  GuidesAPI.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/15/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import "Analytics.h"
#import "GuidesAPI.h"
#import "ExploreGuide.h"

@implementation GuidesAPI

- (void)guidesForLoggedInUserHandler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch user guides from rails"];
    
    NSString *path = @"/guides/user.json";
    
    NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSString *query = [NSString stringWithFormat:@"locale=%@-%@", language, countryCode];
    
    [self fetch:path query:query classMapping:ExploreGuide.class handler:done];
}

- (void)guidesNearLocation:(CLLocationCoordinate2D)coordinate handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch nearby guides from rails"];
    
    NSString *path = @"/guides.json";
    
    NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSString *query = [NSString stringWithFormat:@"latitude=%f&longitude=%f&locale=%@-%@",
                     coordinate.latitude, coordinate.longitude, language, countryCode];
    
    [self fetch:path query:query classMapping:ExploreGuide.class handler:done];
}

- (void)guidesMatching:(NSString *)searchTerm handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - search for guides from rails"];
    
    NSString *path = @"/guides/search";
    
    NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSString *query = [NSString stringWithFormat:@"locale=%@-%@&q=%@",
                      language, countryCode, searchTerm];
    
    [self fetch:path query:query classMapping:ExploreGuide.class handler:done];
}

@end
