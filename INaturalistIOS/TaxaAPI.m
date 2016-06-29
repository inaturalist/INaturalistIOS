//
//  TaxaAPI.m
//  iNaturalist
//
//  Created by Alex Shepard on 6/25/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "TaxaAPI.h"
#import "ExploreTaxon.h"
#import "Analytics.h"
#import "NSLocale+INaturalist.h"

@implementation TaxaAPI

- (void)taxaMatching:(NSString *)name handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch autocomplete taxa"];
    NSString *path = [NSString stringWithFormat:@"taxa/autocomplete?q=%@", name];
    
    NSString *localeString = [NSLocale inat_serverFormattedLocale];
	if (localeString && ![localeString isEqualToString:@""]) {
		path = [path stringByAppendingString:[NSString stringWithFormat:@"&locale=%@", localeString]];
	}
	
    [self fetch:path classMapping:[ExploreTaxon class] handler:done];
}

- (void)taxonWithId:(NSInteger)taxonId handler:(INatAPIFetchCompletionCountHandler)done {
	[[Analytics sharedClient] debugLog:@"Network - fetch taxon by id"];
    NSString *path = [NSString stringWithFormat:@"taxa/%ld", (long)taxonId];
    
    NSString *localeString = [NSLocale inat_serverFormattedLocale];
	if (localeString && ![localeString isEqualToString:@""]) {
		path = [path stringByAppendingString:[NSString stringWithFormat:@"?locale=%@", localeString]];
	}
	
    [self fetch:path classMapping:[ExploreTaxon class] handler:done];

}


@end
