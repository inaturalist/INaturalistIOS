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

- (void)fetch:(NSString *)path mapping:(RKObjectMapping *)mapping handler:(INatAPIFetchCompletionHandler)done {
	done(@[], nil);
	return;
	
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", [self apiBaseUrl], path];
    NSString *localeString = [NSLocale inat_serverFormattedLocale];
    if (localeString && ![localeString isEqualToString:@""]) {
        urlString = [urlString stringByAppendingFormat:@"?locale=%@", localeString];
    }
    NSURL *url = [NSURL URLWithString:urlString];
    if (url) {
        NSURLSession *session = [NSURLSession sharedSession];
        [[session dataTaskWithURL:url
                completionHandler:^(NSData *data,
                                    NSURLResponse *response,
                                    NSError *error) {
                    
                    if (error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            done(nil, error);
                        });
                    } else {
                        NSError *error = nil;
                        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                                             options:NSJSONReadingAllowFragments
                                                                               error:&error];
                        
                        if (error) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                done(nil, error);
                            });
                        } else {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                NSArray *resultsArray = [json valueForKey:@"results"];
                                
                                NSMutableArray *output = [NSMutableArray array];
                                for (id result in resultsArray) {
                                    Class mappingClass = [mapping objectClass];
                                    id target = [[mappingClass alloc] init];
                                    RKObjectMappingOperation *operation = [RKObjectMappingOperation mappingOperationFromObject:result
                                                                                                                      toObject:target
                                                                                                                   withMapping:mapping];
                                    NSError *err;
                                    [operation performMapping:&err];
                                    [output addObject:target];
                                }
                                
                                // return this immutably
                                done([NSArray arrayWithArray:output], nil);
                            });
                        }
                    }
                
                }] resume];
        
    }
    
}


- (void)fetchWithCount:(NSString *)path mapping:(RKObjectMapping *)mapping handler:(INatAPIFetchCompletionCountHandler)done {
	done(@[], 0, nil);
	return;
	
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", [self apiBaseUrl], path];
    NSURL *url = [NSURL URLWithString:urlString];
    if (url) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
        [[session dataTaskWithURL:url
                completionHandler:^(NSData *data,
                                    NSURLResponse *response,
                                    NSError *error) {
                    
                    if (error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            done(nil, 0, error);
                        });
                    } else {
                        NSError *error = nil;
                        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                                             options:NSJSONReadingAllowFragments
                                                                               error:&error];
                        
                        if (error) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                done(nil, 0, error);
                            });
                        } else {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                NSArray *resultsArray = [json valueForKey:@"results"];
                                NSInteger totalResults = [[json valueForKey:@"total_results"] integerValue];
                                
                                NSMutableArray *output = [NSMutableArray array];
                                for (id result in resultsArray) {
                                    Class mappingClass = [mapping objectClass];
                                    id target = [[mappingClass alloc] init];
                                    RKObjectMappingOperation *operation = [RKObjectMappingOperation mappingOperationFromObject:result
                                                                                                                      toObject:target
                                                                                                                   withMapping:mapping];
                                    NSError *err = nil;
                                    [operation performMapping:&err];
                                    if (!err) {
                                        [output addObject:target];
                                    }
                                }
                                // return this immutably
                                done([NSArray arrayWithArray:output], totalResults, nil);
                            });
                        }
                    }
                    
                }] resume];
        
    }
    
}

- (void)fetch:(NSString *)path classMapping:(Class)classMapping handler:(INatAPIFetchCompletionCountHandler)done {
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", [self apiBaseUrl], path];
    NSURL *url = [NSURL URLWithString:urlString];
    if (url) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
        [[session dataTaskWithURL:url
                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    if (error) {
                        done(nil, 0, error);
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
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error) {
        done(nil, 0, error);
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
                NSLog(@"ERROR: %@", error);
            }
        }
        done([NSArray arrayWithArray:results], totalResults, nil);
    }
}

@end
