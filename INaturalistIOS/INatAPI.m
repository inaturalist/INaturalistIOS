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
                                done(output, nil);
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
                                done(output, totalResults, nil);
                            });
                        }
                    }
                    
                }] resume];
        
    }
    
}


@end
