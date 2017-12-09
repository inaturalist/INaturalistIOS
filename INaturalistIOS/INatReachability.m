//
//  INatReachability.m
//  iNaturalist
//
//  Created by Alex Shepard on 12/9/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

#import "INatReachability.h"

@implementation INatReachability

+ (INatReachability *)sharedClient {
    static INatReachability *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[INatReachability alloc] init];
        [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    });
    return _sharedClient;
}

- (BOOL)isNetworkReachable {
    return [self isReachabilityDetermined] && [[AFNetworkReachabilityManager sharedManager] isReachable];
}

- (BOOL)isReachabilityDetermined {
    return [[AFNetworkReachabilityManager sharedManager] networkReachabilityStatus] != AFNetworkReachabilityStatusUnknown;
}

@end
