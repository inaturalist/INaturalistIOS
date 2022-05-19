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
#import "ExploreUser.h"
#import "Analytics.h"
#import "INaturalistAppDelegate.h"
#import "LoginController.h"

@implementation PeopleAPI

- (void)fetchMeHandler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - fetch me from node"];
    NSString *path = @"users/me";
    [self fetch:path classMapping:ExploreUser.class handler:done];
}

- (void)setSiteId:(NSInteger)siteId forUserId:(NSInteger)userId handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - set user site via node"];
    NSDictionary *params = @{
                             @"user": @{ @"site_id": @(siteId) },
                             };
    NSString *path = [NSString stringWithFormat:@"users/%ld", (long)userId];
    [self put:path params:params classMapping:nil handler:done];
}

- (void)createUserEmail:(NSString *)email login:(NSString *)login password:(NSString *)password siteId:(NSInteger)siteId license:(NSString *)license localeStr:(NSString *)localeStr handler:(INatAPIFetchCompletionCountHandler) done {
    
    NSDictionary *newUserDict = @{
        @"user": @{
                @"email": email,
                @"login": login,
                @"password": password,
                @"password_confirmation": password,
                @"site_id": @(siteId),
                @"preferred_observation_license": license,
                @"data_transfer_consent": @"true",
                @"pi_consent": @"true",
                @"preferred_photo_license": license,
                @"preferred_sound_license": license,
                @"locale": localeStr,

        },
    };
    
    NSURL *url = [NSURL URLWithString:@"/users.json" relativeToURL:[NSURL inat_baseURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    LoginController *loginController = appDelegate.loginController;
    [request addValue:[loginController anonymousJWT] forHTTPHeaderField:@"Authorization"];

    NSError *error = nil;
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:newUserDict options:0 error:nil];
    if (error) {
        done(nil, 0, error);
    } else {
        request.HTTPBody = JSONData;
        [request addValue:[[NSUserDefaults standardUserDefaults] stringForKey:INatTokenPrefKey]
       forHTTPHeaderField:@"Authorization"];
        [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {\
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    done(nil, 0, error);
                });
            } else {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                if (httpResponse.statusCode == 200) {
                    
                    NSError *jsonError = nil;
                    id json = [NSJSONSerialization JSONObjectWithData:data
                                                              options:NSJSONReadingAllowFragments
                                                                error:&jsonError];
                    
                    if (jsonError) {
                        // can't parse the json, so we can't get a userid
                        // and finish creating the new user, so bail.
                        dispatch_async(dispatch_get_main_queue(), ^{
                            done(nil, 0, jsonError);
                        });
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            done(@[ json ], 1, nil);
                        });
                    }
                } else {
                    // some type of server error, check for JSON text in the response
                    NSError *jsonError = nil;
                    id json = [NSJSONSerialization JSONObjectWithData:data
                                                              options:NSJSONReadingAllowFragments
                                                                error:&jsonError];
                    if (jsonError) {
                        // can't parse the json response, but not 200, so we can't say we succeeded
                        NSError *error = [NSError errorWithDomain:@"org.inaturalist.api.http"
                                                             code:httpResponse.statusCode
                                                         userInfo:nil];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            done(nil, 0, error);
                        });
                    }
                    if ([json valueForKey:@"errors"]) {
                        NSArray *errors = [json valueForKey:@"errors"];
                        NSString *firstErrorText = [errors firstObject];
                        if (firstErrorText) {
                            NSDictionary *userInfo = @{
                                                       NSLocalizedDescriptionKey: firstErrorText,
                                                       };
                            NSError *error = [NSError errorWithDomain:@"org.inaturalist.api.http"
                                                                 code:httpResponse.statusCode
                                                             userInfo:userInfo];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                done(nil, 0, error);
                            });
                        } else {
                            // error array was empty, but not 200, so we can't say we succeeded
                            NSError *error = [NSError errorWithDomain:@"org.inaturalist.api.http"
                                                                 code:httpResponse.statusCode
                                                             userInfo:nil];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                done(nil, 0, error);
                            });
                        }
                    } else {
                        // no error array, but not 200, so we can't say we succeeded
                        NSError *error = [NSError errorWithDomain:@"org.inaturalist.api.http"
                                                             code:httpResponse.statusCode
                                                         userInfo:nil];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            done(nil, 0, error);
                        });
                    }
                }
            }
        }] resume];
    }
}

- (void)removeProfilePhotoForUserId:(NSInteger)userId handler:(INatAPIFetchCompletionCountHandler)done {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"/users/%ld.json", (long)userId]
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

- (void)uploadProfilePhoto:(UIImage *)image forUserId:(NSInteger)userId handler:(INatAPIFetchCompletionCountHandler)done {
    NSData *imageData = UIImageJPEGRepresentation(image, 0.8f);
    if (imageData) {
        // use afnetworking to deal with icky multi-part forms
        NSString *path = [NSString stringWithFormat:@"/users/%ld.json", (long)userId];
        NSString *urlString = [[NSURL URLWithString:path relativeToURL:[NSURL inat_baseURL]] absoluteString];

        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        [manager.requestSerializer setValue:[[NSUserDefaults standardUserDefaults] stringForKey:INatTokenPrefKey]
                         forHTTPHeaderField:@"Authorization"];
        
        NSError *error = nil;
        NSURLRequest *request = [manager.requestSerializer multipartFormRequestWithMethod:@"PUT" URLString:urlString parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileData:imageData
                                        name:@"user[icon]"
                                    fileName:@"icon.jpg"
                                    mimeType:@"image/jpeg"];
        } error:&error];
        
        NSURLSessionDataTask *task = [manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    done(@[], 0, error);
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    done(@[], 0, nil);
                });
            }
        }];
        [task resume];
    }
}

- (void)setUsername:(NSString *)username forUserId:(NSInteger)userId handler:(INatAPIFetchCompletionCountHandler)done {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"/users/%ld.json", (long)userId]
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
            
            // no response data, assume we couldn't change username
            if (!data) {
                done(@[], 0, nil);
            }
            
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

- (void)setEmailAddress:(NSString *)email forUserId:(NSInteger)userId handler:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - set email address via node"];
    NSDictionary *params = @{
                             @"user": @{ @"email": email },
                             };
    NSString *path = [NSString stringWithFormat:@"users/%ld", (long)userId];
    [self put:path params:params classMapping:nil handler:done];
}

- (void)setPrefersNoTracking:(BOOL)preference forUserId:(NSInteger)userId handler:(INatAPIFetchCompletionCountHandler)done {
    
    [[Analytics sharedClient] debugLog:@"Network - set tracking preference via node"];
    NSDictionary *params = @{
        @"user": @{ @"prefers_no_tracking": preference ? @"true" : @"false" }
    };
    NSString *path = [NSString stringWithFormat:@"users/%ld", (long)userId];
    [self put:path params:params classMapping:nil handler:done];
}

- (void)setPrefersShowCommonNames:(BOOL)preference forUserId:(NSInteger)userId handler:(INatAPIFetchCompletionCountHandler)done {
    
    [[Analytics sharedClient] debugLog:@"Network - set show common names preference via node"];
    NSDictionary *params = @{
        @"user": @{ @"prefers_common_names": preference ? @"true" : @"false" }
    };
    NSString *path = [NSString stringWithFormat:@"users/%ld", (long)userId];
    [self put:path params:params classMapping:nil handler:done];
}

- (void)setPrefersShowScientificNamesFirst:(BOOL)preference forUserId:(NSInteger)userId handler:(INatAPIFetchCompletionCountHandler)done {
    
    [[Analytics sharedClient] debugLog:@"Network - set show scientific names first preference via node"];
    NSDictionary *params = @{
        @"user": @{ @"prefers_scientific_name_first": preference ? @"true" : @"false" }
    };
    NSString *path = [NSString stringWithFormat:@"users/%ld", (long)userId];
    [self put:path params:params classMapping:nil handler:done];
}


@end
