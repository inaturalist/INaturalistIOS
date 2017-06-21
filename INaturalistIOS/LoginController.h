//
//  LoginController.h
//  iNaturalist
//
//  Created by Alex Shepard on 5/15/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Partner;
@class User;
@class UploadManager;

extern NSString *kUserLoggedInNotificationName;
extern NSInteger INatMinPasswordLength;

typedef void (^LoginSuccessBlock)(NSDictionary *info);
typedef void (^LoginErrorBlock)(NSError *error);

@interface LoginController : NSObject

- (void)loginWithFacebookViewController:(UIViewController *)vc
	success:(LoginSuccessBlock)success
	failure:(LoginErrorBlock)error;
- (void)loginWithGoogleUsingNavController:(UINavigationController *)nav
                                  success:(LoginSuccessBlock)success
                                  failure:(LoginErrorBlock)error;
- (void)loginWithGoogleUsingViewController:(UIViewController *)parent
                                   success:(LoginSuccessBlock)success
                                   failure:(LoginErrorBlock)error;

- (void)createAccountWithEmail:(NSString *)email
                      password:(NSString *)password
                      username:(NSString *)username
                          site:(NSInteger)siteId
                       license:(NSString *)license
                       success:(LoginSuccessBlock)successBlock
                       failure:(LoginErrorBlock)failureBlock;

- (void)loginWithUsername:(NSString *)username
                 password:(NSString *)password
                  success:(LoginSuccessBlock)successBlock
                  failure:(LoginErrorBlock)failureBlock;

- (void)logout;

- (void)loggedInUserSelectedPartner:(Partner *)partner
                         completion:(void (^)(void))completion;
- (User *)fetchMe;

@property (readonly) BOOL isLoggedIn;
@property UploadManager *uploadManager;

- (void)getJWTTokenSuccess:(LoginSuccessBlock)success failure:(LoginErrorBlock)failure;
@property NSString *jwtToken;
@property (readonly) NSString *anonymousJWT;

@end
