//
//  PeopleAPI.m
//  iNaturalist
//
//  Created by Alex Shepard on 8/2/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

#import "PeopleAPI.h"
#import "NSURL+INaturalist.h"
#import "User.h"
#import "Analytics.h"

@implementation PeopleAPI

- (void)removeProfilePhotoForUser:(User *)user handler:(INatAPIFetchCompletionCountHandler)done {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"/users/%ld.json", (long)user.recordID.integerValue]
                        relativeToURL:[NSURL inat_baseURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"PUT";
    
    NSDictionary *dictionary = @{ @"icon_delete" : @(YES) };
    NSError *error = nil;
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    if (error) {
        done(nil, 0, error);
    } else {
        request.HTTPBody = JSONData;
        [request addValue:[[NSUserDefaults standardUserDefaults] stringForKey:INatTokenPrefKey]
       forHTTPHeaderField:@"Authorization"];
        [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    done(nil, 0, error);
                } else {
                    done(@[], 0, nil);
                }
            });
        }] resume];
    }
}

- (void)uploadProfilePhoto:(UIImage *)image forUser:(User *)user handler:(INatAPIFetchCompletionCountHandler)done {
    NSData *imageData = UIImageJPEGRepresentation(image, 0.8f);
    if (imageData) {
        // use afnetworking to deal with icky multi-part forms
        NSString *path = [NSString stringWithFormat:@"/users/%ld.json", (long)user.recordID.integerValue];
        AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL inat_baseURL]];
        
        NSString *urlString = [[NSURL URLWithString:path relativeToURL:[NSURL inat_baseURL]] absoluteString];
        NSMutableURLRequest *request = [[manager.requestSerializer multipartFormRequestWithMethod:@"PUT"
                                                                                        URLString:urlString
                                                                                       parameters:nil
                                                                        constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                                                                            [formData appendPartWithFileData:imageData
                                                                                                        name:@"user[icon]"
                                                                                                    fileName:@"icon.jpg"
                                                                                                    mimeType:@"image/jpeg"];
                                                                        }
                                                                                            error:nil] mutableCopy];
        [request addValue:[[NSUserDefaults standardUserDefaults] stringForKey:INatTokenPrefKey]
       forHTTPHeaderField:@"Authorization"];
        
        AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            dispatch_async(dispatch_get_main_queue(), ^{
                done(@[], 0, nil);
            });
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                done(@[], 0, error);
            });
        }];
        [manager.operationQueue addOperation:operation];
    }
}

- (void)setUsername:(NSString *)username forUser:(User *)user handler:(INatAPIFetchCompletionCountHandler)done {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"/users/%ld.json", (long)user.recordID.integerValue]
                        relativeToURL:[NSURL inat_baseURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"PUT";
    
    NSDictionary *dictionary = @{ @"login" : username };
    NSError *error = nil;
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    if (error) {
        done(nil, 0, error);
    } else {
        request.HTTPBody = JSONData;
        [request addValue:[[NSUserDefaults standardUserDefaults] stringForKey:INatTokenPrefKey]
       forHTTPHeaderField:@"Authorization"];
        [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if ([httpResponse statusCode] != 200) {
                NSError *jsonError;
                NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                           options:NSJSONReadingAllowFragments
                                                                             error:&jsonError];
                if (!jsonError && [dictionary valueForKey:@"errors"]) {
                    // this error comes back as { errors: { key: ( valueError ) } }
                    NSDictionary *errors = [dictionary valueForKey:@"errors"];
                    NSString *errorKey = [[errors allKeys] firstObject];
                    NSArray *errorValues = (NSArray *)errors[errorKey];
                    NSString *errorString = [NSString stringWithFormat:@"%@ %@", errorKey, [errorValues firstObject]];
                    NSDictionary *info = @{NSLocalizedDescriptionKey: errorString };
                    NSError *error = [NSError errorWithDomain:@"org.inaturalist.ios"
                                                         code:[httpResponse statusCode]
                                                     userInfo:info];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        done(nil, 0, error);
                    });
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        done(nil, 0, error);
                    } else {
                        done(@[], 0, nil);
                    }
                });
            }
        }] resume];
    }

}

@end
