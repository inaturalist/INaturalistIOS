//
//  INatAPI.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "INatAPI.h"

@implementation INatAPI

- (NSString *)apiBaseUrl {
    return @"http://api.inaturalist.org/v1";
}

- (void)fetch:(NSString *)path mapping:(RKObjectMapping *)mapping handler:(INatAPIFetchCompletionHandler)done {
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", [self apiBaseUrl], path];
    NSURL *url = [NSURL URLWithString:urlString];
    if (url) {
        NSURLSession *session = [NSURLSession sharedSession];
        [[session dataTaskWithURL:url
                completionHandler:^(NSData *data,
                                    NSURLResponse *response,
                                    NSError *error) {
                    
                    if (error) {
                        done(nil, error);
                    } else {
                        NSError *error = nil;
                        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                                             options:NSJSONReadingAllowFragments
                                                                               error:&error];
                        
                        if (error) {
                            done(nil, error);
                        } else {
                            NSArray *resultsArray = [json valueForKey:@"results"];
                            
                            RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider new];
                            [mappingProvider setMapping:mapping forKeyPath:@""];
                            
                            RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:resultsArray
                                                                      mappingProvider:mappingProvider];
                            RKObjectMappingResult *result = [mapper performMapping];
                            // TODO: check for .asError here?
                            dispatch_async(dispatch_get_main_queue(), ^{
                                done(result.asCollection, nil);
                            });
                        }
                    }
                    
                }] resume];

    }

}


- (void)fetchWithCount:(NSString *)path mapping:(RKObjectMapping *)mapping handler:(INatAPIFetchCompletionCountHandler)done {
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
                        done(nil, 0, error);
                    } else {
                        NSError *error = nil;
                        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                                             options:NSJSONReadingAllowFragments
                                                                               error:&error];
                        
                        if (error) {
                            done(nil, 0, error);
                        } else {
                            NSArray *resultsArray = [json valueForKey:@"results"];
                            NSInteger totalResults = [[json valueForKey:@"total_results"] integerValue];
                            RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider new];
                            [mappingProvider setMapping:mapping forKeyPath:@""];
                            
                            RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:resultsArray
                                                                      mappingProvider:mappingProvider];
                            RKObjectMappingResult *result = [mapper performMapping];
                            // TODO: check for .asError here?
                            dispatch_async(dispatch_get_main_queue(), ^{
                                done(result.asCollection, totalResults, nil);
                            });
                        }
                    }
                    
                }] resume];
        
    }
    
}


@end
