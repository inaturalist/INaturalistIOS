//
//  TaxaAPI.m
//  iNaturalist
//
//  Created by Alex Shepard on 6/25/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

#import "TaxaAPI.h"
#import "ExploreTaxon.h"
#import "Analytics.h"
#import "NSLocale+INaturalist.h"
#import "ImageStore.h"
#import "INaturalistAppDelegate.h"
#import "LoginController.h"
#import "ExploreTaxonScore.h"
#import "NSURL+INaturalist.h"

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
    NSString *path = [NSString stringWithFormat:@"observations?taxon_id=%ld&per_page=1&return_bounds=true",
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


- (void)extractSuggestionsFromDictionary:(NSDictionary *)jsonDict classMapping:(Class)classForMapping handler:(INatAPISuggestionsCompletionHandler)done {
    NSMutableArray *results = [NSMutableArray array];
    
    for (NSDictionary *resultJSON in [jsonDict valueForKey:@"results"]) {
        NSError *error;
        MTLModel *result = [MTLJSONAdapter modelOfClass:classForMapping
                                     fromJSONDictionary:resultJSON
                                                  error:&error];
        
        if (result) {
            [results addObject:result];
        } else {
            // skip this one
            NSLog(@"MANTLE ERROR: %@", error);
        }
    }
    
    ExploreTaxon *commonAncestor = nil;
    if ([jsonDict valueForKeyPath:@"common_ancestor.taxon"]) {
        NSDictionary *taxon = [jsonDict valueForKeyPath:@"common_ancestor.taxon"];
        NSError *error = nil;
        commonAncestor = [MTLJSONAdapter modelOfClass:ExploreTaxon.class
                                   fromJSONDictionary:taxon
                                                error:&error];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        done([NSArray arrayWithArray:results], commonAncestor, nil);
    });
}

// extract objects from server response data
- (void)extractSuggestionsFromData:(NSData *)data classMapping:(Class)classForMapping handler:(INatAPISuggestionsCompletionHandler)done {
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            done(nil, nil, error);
        });
    } else {
        [self extractSuggestionsFromDictionary:json
                                  classMapping:classForMapping
                                       handler:done];
    }
}

- (void)suggestionsForObservationId:(NSInteger)observationId handler:(INatAPISuggestionsCompletionHandler)done {
    //  https://api.inaturalist.org/v1/computervision/score_observation/1000000

    
    [[Analytics sharedClient] debugLog:@"Network - fetch suggestions by id"];
    NSString *path = [NSString stringWithFormat:@"computervision/score_observation/%ld", (long)observationId];
    
    NSString *localeString = [NSLocale inat_serverFormattedLocale];
    if (localeString && ![localeString isEqualToString:@""]) {
        path = [path stringByAppendingString:[NSString stringWithFormat:@"?locale=%@", localeString]];
    }
    
    path = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", [self apiBaseUrl], path];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    LoginController *login = appDelegate.loginController;
    // only using the anonymous JWT for the suggestions API right now
    [request addValue:[login anonymousJWT] forHTTPHeaderField:@"Authorization"];
    
    if (url) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
        [[session dataTaskWithRequest:request
                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                        if ([httpResponse statusCode] != 200) {
                            NSError *jsonError = nil;
                            NSString *errString = nil;
                            NSDictionary *json = nil;
                            if (data) {
                                json = [NSJSONSerialization JSONObjectWithData:data
                                                                       options:NSJSONReadingAllowFragments
                                                                         error:&jsonError];
                            }
                            if (!jsonError && json && [json valueForKey:@"error"]) {
                                errString = [json valueForKey:@"error"];
                            } else {
                                errString = [NSHTTPURLResponse localizedStringForStatusCode:[httpResponse statusCode]];
                            }
                            NSError *err = [NSError errorWithDomain:NSURLErrorDomain
                                                               code:[httpResponse statusCode]
                                                           userInfo:@{
                                                                      NSLocalizedDescriptionKey: errString,
                                                                      }];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                done(nil, nil, err);
                            });
                        } else if (error) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                done(nil, nil, error);
                            });
                        } else {
                            [self extractSuggestionsFromData:data
                                                classMapping:ExploreTaxonScore.class
                                                     handler:done];
                        }
                    }] resume];
    }

}

- (void)suggestionsForImage:(UIImage *)image location:(CLLocationCoordinate2D)coordinate date:(NSDate *)observedOn handler:(INatAPISuggestionsCompletionHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch suggestions by image"];
    NSString *path = @"computervision/score_image";
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (CLLocationCoordinate2DIsValid(coordinate)) {
        params[@"lat"] = @(coordinate.latitude);
        params[@"lng"] = @(coordinate.longitude);
    }
    if (observedOn) {
        params[@"observed_on"] = @([observedOn timeIntervalSince1970]);
    }
    
    UIImage *thumb = [[ImageStore class] imageWithImage:image
                                     squashedToFillSize:CGSizeMake(299, 299)];
    NSData *imageData = UIImageJPEGRepresentation(thumb, 0.9);

    // use afnetworking to deal with icky multi-part forms
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:self.apiBaseUrl]];

    AFHTTPRequestSerializer *requestSerializer = [[AFHTTPRequestSerializer alloc] init];
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    LoginController *login = appDelegate.loginController;
    // only using the anonymous JWT for the suggestions API right now
    [requestSerializer setValue:[login anonymousJWT] forHTTPHeaderField:@"Authorization"];
    manager.requestSerializer = requestSerializer;
    
    [manager POST:path parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:imageData
                                    name:@"image"
                                fileName:@"file.jpg"
                                mimeType:@"image/jpeg"];
    } success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        [self extractSuggestionsFromDictionary:responseObject
                                  classMapping:ExploreTaxonScore.class
                                       handler:done];
    } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            done(nil, nil, error);
        });
    }];

}

@end
