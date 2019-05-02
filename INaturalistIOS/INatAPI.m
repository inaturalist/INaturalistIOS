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

- (void)delete:(NSString *)path handler:(INatAPIFetchCompletionCountHandler)done {
    [self requestMethod:@"DELETE" path:path params:nil classMapping:nil handler:done];
}

- (NSString *)apiBaseUrl {
    return @"https://api.inaturalist.org/v1";
}

- (void)requestMethod:(NSString *)method path:(NSString *)path params:(NSDictionary *)params jwt:(NSString *)jwtToken classMapping:(Class)classForMapping handler:(INatAPIFetchCompletionCountHandler)done {
    
    NSString *escapedPath = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", [self apiBaseUrl], escapedPath];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = method;
    
    if (jwtToken) {
        [request addValue:jwtToken forHTTPHeaderField:@"Authorization"];
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
        __weak typeof(self)weakSelf = self;
        [[session dataTaskWithRequest:request
                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                        if (error) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                done(nil, 0, error);
                            });
                        } else {
                            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                            if (httpResponse.statusCode != 200) {
                                NSString *baseErrorText = NSLocalizedString(@"Unknown Error: %ld", @"message to the user when we get an unknown error. the %ld will be a status code");
                                NSString *errorText = [NSString stringWithFormat:baseErrorText, httpResponse.statusCode];
                                if (data) {
                                    // this seems to be how we get errors back from node
                                    id json = [NSJSONSerialization JSONObjectWithData:data options:nil error:nil];
                                    
                                    @try {
                                        id originalErrors = [json valueForKeyPath:@"error.original.errors"];
                                        if (originalErrors) {
                                            id firstKey = [[originalErrors allKeys] firstObject];
                                            id firstValue = [originalErrors[firstKey] firstObject];
                                            errorText = [NSString stringWithFormat:@"%@ %@", firstKey, firstValue];
                                        }
                                    }
                                    @catch (NSException *exception) { }
                                }
                                
                                NSDictionary *userInfo = @{
                                                           NSLocalizedDescriptionKey: errorText,
                                                           };
                                NSError *error = [NSError errorWithDomain:@"org.inaturalist.api.http"
                                                                     code:httpResponse.statusCode
                                                                 userInfo:userInfo];
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    done(nil, 0, error);
                                });
                            } else {
                                if (classForMapping) {
                                    [weakSelf extractObjectsFromData:data
                                                        classMapping:classForMapping
                                                             handler:done];
                                } else {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        done(nil, 0, nil);
                                    });
                                }
                            }
                        }
                    }] resume];
    }
}

- (void)requestMethod:(NSString *)method path:(NSString *)path params:(NSDictionary *)params classMapping:(Class)classForMapping handler:(INatAPIFetchCompletionCountHandler)done {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.loggedIn) {
        __weak typeof(self)weakSelf = self;
        [appDelegate.loginController getJWTTokenSuccess:^(NSDictionary *info) {
            [weakSelf requestMethod:method path:path params:params jwt:info[@"token"] classMapping:classForMapping handler:done];
        } failure:^(NSError *error) {
            done(nil, 0, error);
        }];
    } else {
        [self requestMethod:method path:path params:params jwt:nil classMapping:classForMapping handler:done];
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
        
        if ([json isKindOfClass:[NSDictionary class]]) {
            NSString *totalResultsKey = @"total_results";
            if ([json valueForKey:totalResultsKey] && [json valueForKey:totalResultsKey] != [NSNull null]) {
                totalResults = [[json valueForKey:totalResultsKey] integerValue];
            }
            
            if ([json valueForKey:@"results"]) {
                // sometimes results from node come back inside a results
                // variable in the response dictionary
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
            } else {
                // sometimes results from node come back as a bare object
                NSError *error;
                MTLModel *result = [MTLJSONAdapter modelOfClass:ClassForMapping
                                             fromJSONDictionary:json
                                                          error:&error];
                if (result) {
                    [results addObject:result];
                    totalResults = 1;
                } else {
                    // skip this one
                    NSLog(@"MANTLE ERROR: %@", error);
                }
            }
        } else {
            // sometimes results from node come back as an array of objects
            for (id jsonObject in json) {
                NSError *error;
                MTLModel *result = [MTLJSONAdapter modelOfClass:ClassForMapping
                                             fromJSONDictionary:jsonObject
                                                          error:&error];
                if (result) {
                    [results addObject:result];
                    // total results is unknown, can't set
                } else {
                    // skip this one
                    NSLog(@"MANTLE ERROR: %@", error);
                }

            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            done([NSArray arrayWithArray:results], totalResults, nil);
        });
    }
}

@end
