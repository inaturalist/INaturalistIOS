//
//  YearInReviewAPI.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/8/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import "YearInReviewAPI.h"

@implementation YearInReviewAPI

static NSString *LoggedInUserHasGeneratedStatsFor2019Key = @"LoggedInUserHasGeneratedStatsFor2019";
static NSString *LoggedInUserHasGeneratedStatsFor2020Key = @"LoggedInUserHasGeneratedStatsFor2020";


- (NSString *)generateStatsKeyForYear:(NSInteger)year {
    if (year == 2019) {
        return LoggedInUserHasGeneratedStatsFor2019Key;
    } else {
        return nil;
    }
}

- (BOOL)loggedInUserHasGeneratedStatsForYear:(NSInteger)year {
    NSString *key = [self generateStatsKeyForYear:year];
    if (key) {
        return [[NSUserDefaults standardUserDefaults] boolForKey:LoggedInUserHasGeneratedStatsFor2019Key];
    } else {
        return NO;
    }
}

- (void)setLoggedInUserHasGeneratedStatsForYear:(NSInteger)year newValue:(BOOL)newValue {
    NSString *key = [self generateStatsKeyForYear:year];
    [[NSUserDefaults standardUserDefaults] setBool:newValue
                                            forKey:key];
}

- (void)checkIfYiRStatsGeneratedForUser:(NSString *)username year:(NSInteger)year {
    NSString *path = [NSString stringWithFormat:@"/stats/%ld/%@.json", (long)year, username];
    
    NSString *escapedPath = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", [self apiBaseUrl], escapedPath];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"HEAD";
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];

    if (url) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
        [[session dataTaskWithRequest:request
                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 200) {
                [self setLoggedInUserHasGeneratedStatsForYear:year newValue:YES];
            }
            
        }] resume];
    }
}
         
- (void)generateYiRStatsForYear:(NSInteger)year handler:(INatAPIYiRStatsHandler)done {
    NSString *path = [NSString stringWithFormat:@"/stats/generate_year?year=%ld", (long)year];
    
    NSString *escapedPath = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", [self apiBaseUrl], escapedPath];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    
    if ([self authToken]) {
        [request addValue:[self authToken] forHTTPHeaderField:@"Authorization"];
    } else {
        // can't generate stats if you're not logged in
        dispatch_async(dispatch_get_main_queue(), ^{
            done(false, nil);
        });
    }
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    if (url) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
        [[session dataTaskWithRequest:request
                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 200) {
                //update loggedInUserHasGeneratedStatsForCurrentYear to true
                [self setLoggedInUserHasGeneratedStatsForYear:year newValue:YES];
                dispatch_async(dispatch_get_main_queue(), ^{
                    done(true, nil);
                });
            } else if (httpResponse.statusCode == 202) {
                //update loggedInUserHasGeneratedStatsForCurrentYear to false
                [self setLoggedInUserHasGeneratedStatsForYear:year newValue:NO];
                dispatch_async(dispatch_get_main_queue(), ^{
                    done(false, nil);
                });
            } else if (error) {
                [self setLoggedInUserHasGeneratedStatsForYear:year newValue:NO];
                dispatch_async(dispatch_get_main_queue(), ^{
                    done(false, error);
                });
            }
        }] resume];
    }
}

@end
