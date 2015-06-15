//
//  LoginController.h
//  iNaturalist
//
//  Created by Alex Shepard on 5/15/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *kUserLoggedInNotificationName;
extern NSInteger INatMinPasswordLength;

typedef void (^LoginSuccessBlock)(NSDictionary *info);
typedef void (^LoginErrorBlock)(NSError *error);

@interface LoginController : NSObject

- (void)loginWithFacebookSuccess:(LoginSuccessBlock)success
                         failure:(LoginErrorBlock)error;
- (void)loginWithGoogleUsingNavController:(UINavigationController *)nav
                                  success:(LoginSuccessBlock)success
                                  failure:(LoginErrorBlock)error;

- (void)createAccountWithEmail:(NSString *)email
                      password:(NSString *)password
                      username:(NSString *)username
                       license:(NSString *)license
                       success:(LoginSuccessBlock)successBlock
                       failure:(LoginErrorBlock)failureBlock;

- (void)loginWithUsername:(NSString *)username
                 password:(NSString *)password
                  success:(LoginSuccessBlock)successBlock
                  failure:(LoginErrorBlock)failureBlock;

- (void)logout;

@end
