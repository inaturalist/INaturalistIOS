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

- (void)boundingBoxForTaxon:(NSInteger)taxonId handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - bounding box for taxon"];
    NSString *path = [NSString stringWithFormat:@"observations?taxon_id=%ld&per_page=1&return_bounds=true&verifiable=true",
                      (long)taxonId];
    
    path = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", [self apiBaseUrl], path];
    NSURL *url = [NSURL URLWithString:urlString];
    
    if (url) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
        [[session dataTaskWithRequest:[NSURLRequest requestWithURL:url]
                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                        if (error) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                done(nil, 0, error);
                            });
                        } else {
                            NSError *error;
                            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                            if (error) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    done(nil, 0, error);
                                });
                            } else {
                                NSInteger totalResults = [[json valueForKey:@"total_results"] integerValue];

                                if ([json valueForKey:@"total_bounds"]) {
                                    done(@[ [json valueForKey:@"total_bounds"] ], totalResults, nil);
                                } else {
                                    done(nil, 0, nil);
                                }
                            }
                        }
                    }] resume];
    }
    

}


@end
