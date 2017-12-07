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
#import "INaturalistAppDelegate.h"
#import "LoginController.h"

@implementation INatAPI

- (void)post:(NSString *)path params:(NSDictionary *)params classMapping:(Class)classForMapping handler:(INatAPIFetchCompletionCountHandler)done {
    [self requestMethod:@"POST" path:path params:params classMapping:classForMapping handler:done];
}

- (void)put:(NSString *)path params:(NSDictionary *)params classMapping:(Class)classForMapping handler:(INatAPIFetchCompletionCountHandler)done {
    [self requestMethod:@"PUT" path:path params:params classMapping:classForMapping handler:done];
}

- (void)fetch:(NSString *)path classMapping:(Class)classForMapping handler:(INatAPIFetchCompletionCountHandler)done {
    [self requestMethod:@"GET" path:path params:nil classMapping:classForMapping handler:done];
}

- (NSString *)apiBaseUrl {
    return @"https://api.inaturalist.org/v1";
}

- (void)requestMethod:(NSString *)method path:(NSString *)path params:(NSDictionary *)params classMapping:(Class)classForMapping handler:(INatAPIFetchCompletionCountHandler)done {
    
    path = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", [self apiBaseUrl], path];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = method;
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    LoginController *login = appDelegate.loginController;
    if ([login jwtToken]) {
        [request addValue:[login jwtToken]
       forHTTPHeaderField:@"Authorization"];
    }
    
    if (params) {
        NSError *paramsErr = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&paramsErr];
        if (paramsErr) {
            dispatch_async(dispatch_get_main_queue(), ^{
                done(nil, 0, paramsErr);
            });
            return;
        }
        request.HTTPBody = jsonData;
        [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    }
    
    
    if (url) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
        [[session dataTaskWithRequest:request
                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                        if (error) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                done(nil, 0, error);
                            });
                        } else {
                            if (classForMapping) {
                                [self extractObjectsFromData:data
                                                classMapping:classForMapping
                                                     handler:done];
                            } else {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    done(nil, 0, nil);
                                });
                            }
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
        NSInteger totalResults = 0;
        NSString *totalResultsKey = @"total_results";
        if ([json valueForKey:totalResultsKey] && [json valueForKey:totalResultsKey] != [NSNull null]) {
            totalResults = [[json valueForKey:totalResultsKey] integerValue];
        }
        
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
