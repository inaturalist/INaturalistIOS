//
//  INatRailsAPI.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/15/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import "INatRailsAPI.h"

@implementation INatRailsAPI

- (NSString *)apiBaseUrl {
    return @"https://www.inaturalist.org/";
}

- (NSString *)authToken {
    return [[NSUserDefaults standardUserDefaults] objectForKey:INatTokenPrefKey];
}

- (void)requestMethod:(NSString *)method path:(NSString *)path query:(NSString *)query params:(NSDictionary *)params classMapping:(Class)classForMapping handler:(INatAPIFetchCompletionCountHandler)done {
        
    NSURLComponents *components = [NSURLComponents componentsWithString:[self apiBaseUrl]];
    components.path = path;
    if (query) {
        components.query = query;
    }
    
    NSURL *url = components.URL;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = method;
    
    if ([self authToken]) {
        [request addValue:[self authToken] forHTTPHeaderField:@"Authorization"];
    }
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];

    // not handling params for now
    NSAssert(params == nil, @"Params must be nil in INatRailsAPI");
    
    if (url) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
        [[session dataTaskWithRequest:request
                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                // check for errors
                dispatch_async(dispatch_get_main_queue(), ^{
                    done(nil, 0, error);
                });
            } else if (((NSHTTPURLResponse *)response).statusCode != 200) {
                // check for non success response code
                NSError *error = [NSError errorWithDomain:@"org.inaturalist.rails.http"
                                                     code:((NSHTTPURLResponse *)response).statusCode
                                                 userInfo:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    done(nil, 0, error);
                });
            } else if (data && data.length > 0 && classForMapping) {
                // check for response body
                [self extractObjectsFromData:data classMapping:classForMapping handler:done];
            } else {
                // if no response body
                dispatch_async(dispatch_get_main_queue(), ^{
                    done(@[ ], 0, nil);
                });
            }
            
        }] resume];
    }
}

- (void)extractObjectsFromData:(NSData *)data classMapping:(Class)ClassForMapping handler:(INatAPIFetchCompletionCountHandler)done {
    NSError *error;
    id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            done(nil, 0, error);
        });
    } else {
        NSMutableArray *results = [NSMutableArray array];
        for (NSDictionary *resultJSON in json) {
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
            done([NSArray arrayWithArray:results], [results count], nil);
        });
    }
}


@end
