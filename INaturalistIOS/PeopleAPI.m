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
        AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL inat_baseURL]];
        
        NSString *path = [NSString stringWithFormat:@"/users/%ld.json", (long)user.recordID.integerValue];
        
        NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"PUT"
                                                                             path:path
                                                                       parameters:nil
                                                        constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
                                                            [formData appendPartWithFileData:imageData
                                                                                        name:@"user[icon]"
                                                                                    fileName:@"icon.jpg"
                                                                                    mimeType:@"image/jpeg"];
                                                            
                                                        }];
        [request addValue:[[NSUserDefaults standardUserDefaults] stringForKey:INatTokenPrefKey]
       forHTTPHeaderField:@"Authorization"];
        
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            dispatch_async(dispatch_get_main_queue(), ^{
                done(@[], 0, nil);
            });
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                done(nil, 0, error);
            });
        }];
        [httpClient enqueueHTTPRequestOperation:operation];
    }
}
@end
