//
//  AnonymousJWTHelper.m
//  iNaturalist
//
//  Created by Alex Shepard on 9/26/22.
//  Copyright © 2022 iNaturalist. All rights reserved.
//

@import JWT;

#import "AnonymousJWTHelper.h"

@implementation AnonymousJWTHelper

+ (NSString *)anonymousJWT {
#ifdef INatAnonymousAPISecret
    JWTClaimsSet *claimsSet = [[JWTClaimsSet alloc] init];
    claimsSet.expirationDate = [[NSDate date] dateByAddingTimeInterval:300];
    NSDate *expiration = [[NSDate date] dateByAddingTimeInterval:300];
    NSTimeInterval expirationStamp = [expiration timeIntervalSince1970];
    
    NSDictionary *payload = @{
                              @"application" : @"ios",
                              @"exp": @((NSInteger)expirationStamp),
                              };
    
    id<JWTAlgorithm> algorithm = [JWTAlgorithmFactory algorithmByName:@"HS512"];
    
    // TODO: latest implementation of this cocoapod (3.0) is still in beta
    // the 2.2 version works but the methods are deprecated, but no new implemntation
    // will be ready until 3.0. maybe best to just switch to a swift library for this.
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

    NSString *encoded = [JWTBuilder encodePayload:payload].secret(INatAnonymousAPISecret).algorithm(algorithm).encode;
    return encoded;

#pragma clang diagnostic pop

#else
    return nil;
#endif
}

@end
