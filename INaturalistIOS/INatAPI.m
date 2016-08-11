//
//  INatAPI.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Mantle/Mantle.h>

#import "ExploreObservation.h"
#import "INatAPI.h"
#import "NSLocale+INaturalist.h"

@implementation INatAPI

- (NSString *)apiBaseUrl {
    return @"http://api.inaturalist.org/v1";
}




- (void)fetch:(NSString *)path classMapping:(Class)classMapping handler:(INatAPIFetchCompletionCountHandler)done {
    path = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", [self apiBaseUrl], path];
    
    NSURLComponents *components = [NSURLComponents componentsWithString:urlString];
    NSURLQueryItem *ttl = [NSURLQueryItem queryItemWithName:@"ttl" value:@"-1"];
    [components setQueryItems:[[components queryItems] arrayByAddingObject:ttl]];
    
    NSURL *url = [components URL];
    if (url) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.URLCache = nil;
        config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
        [[session dataTaskWithURL:url
                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    if (error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            done(nil, 0, error);
                        });
                    } else {
                        [self extractObjectsFromData:data
                                        classMapping:classMapping
                                             handler:done];
                    }
                }] resume];
    }
}

// extract objects from server response data
- (void)extractObjectsFromData:(NSData *)data classMapping:(Class)ClassForMapping handler:(INatAPIFetchCompletionCountHandler)done {
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            done(nil, 0, error);
        });
    } else {
        NSMutableArray *results = [NSMutableArray array];
        NSInteger totalResults = [[json valueForKey:@"total_results"] integerValue];
        
        for (NSDictionary *resultJSON in [json valueForKey:@"results"]) {
            NSError *error;
            MTLModel *result = [MTLJSONAdapter modelOfClass:ClassForMapping
                                         fromJSONDictionary:resultJSON
                                                      error:&error];
            
            if (result) {
                [results addObject:result];
            } else {
                // skip this one
                NSLog(@"MANTLE ERROR: %@", error);
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            done([NSArray arrayWithArray:results], totalResults, nil);
        });
    }
}

@end
