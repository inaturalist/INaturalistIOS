//
//  LoginController.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/15/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <FacebookSDK/FacebookSDK.h>
#import <NXOAuth2Client/NXOAuth2.h>
#import "GPPSignIn.h"

#import "LoginController.h"
#import "Analytics.h"
#import "INaturalistAppDelegate.h"
#import "GooglePlusAuthViewController.h"


@interface LoginController () {
    NSString    *externalAccessToken;
    NSString    *iNatAccessToken;
    NSString    *accountType;
    BOOL        isLoginCompleted;
    NSInteger   lastAssertionType;
    BOOL        tryingGoogleReauth;
}

@end

#pragma mark - NSNotification names

NSString *kUserLoggedInNotificationName = @"UserLoggedInNotificationName";

@implementation LoginController

- (instancetype)init {
    if (self = [super init]) {
        [self initOAuth2Service];
        [self initGoogleLogin];
    }
    
    return self;
}

- (void)logout {
    
}

- (void)createAccountWithEmail:(NSString *)email
                      password:(NSString *)password
                      username:(NSString *)username
                       success:(LoginSuccessBlock)successBlock
                       failure:(LoginErrorBlock)failureBlock {
    
    [[RKClient sharedClient] post:@"/users.json"
                       usingBlock:^(RKRequest *request) {
                           request.params = @{
                                              @"user[email]": email,
                                              @"user[login]": username,
                                              @"user[password]": password,
                                              @"user[password_confirmation]": password,
                                              };
                           
                           request.onDidLoadResponse = ^(RKResponse *response) {
                               NSError *error = nil;
                               id respJson = [NSJSONSerialization JSONObjectWithData:response.body
                                                                             options:NSJSONReadingAllowFragments
                                                                               error:&error];
                               if (error) {
                                   failureBlock(error);
                                   return;
                               }
                               
                               if ([respJson valueForKey:@"errors"]) {
                                   // TODO: extract error from json and notify user
                                   failureBlock(nil);
                                   return;
                               }
                               
                               [self loginWithUsername:username
                                              password:password
                                               success:successBlock
                                               failure:failureBlock];
                               
                           };
                           
                           request.onDidFailLoadWithError = ^(NSError *error) {
                               failureBlock(error);
                           };

                       }];
}

- (void)loginWithUsername:(NSString *)username
                 password:(NSString *)password
                  success:(LoginSuccessBlock)successBlock
                  failure:(LoginErrorBlock)failureBlock {

    accountType = nil;
    accountType = kINatAuthService;
    isLoginCompleted = NO;
    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:accountType
                                                              username:username
                                                              password:password];

}

- (void)loginWithFacebookSuccess:(LoginSuccessBlock)successBlock failure:(LoginErrorBlock)failBlock {
    NSArray *perms = @[@"email", @"offline_access", @"user_photos", @"friends_photos", @"user_groups"];
    FBSession *session = [[FBSession alloc] initWithAppID:nil
                                              permissions:perms
                                          urlSchemeSuffix:@"inat"
                                       tokenCacheStrategy:nil];
    [FBSession setActiveSession:session];
    [session openWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent
            completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                
                switch (state) {
                    case FBSessionStateOpen:
                        externalAccessToken = [session.accessTokenData.accessToken copy];
                        accountType = nil;
                        accountType = kINatAuthServiceExtToken;
                        [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:accountType
                                                                             assertionType:[NSURL URLWithString:@"http://facebook.com"]
                                                                                 assertion:externalAccessToken];
                        [[Analytics sharedClient] event:kAnalyticsEventLogin
                                         withProperties:@{ @"Via": @"Facebook" }];
                        [((INaturalistAppDelegate *)[UIApplication sharedApplication].delegate) showMainUI];
                        [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoggedInNotificationName
                                                                            object:nil];
                        
                        break;
                    case FBSessionStateClosed:
                        NSLog(@"session FBSessionStateClosed");
                    case FBSessionStateClosedLoginFailed:
                        NSLog(@"session FBSessionStateClosedLoginFailed");
                        // Once the user has logged in, we want them to
                        // be looking at the root view.
                        [FBSession.activeSession closeAndClearTokenInformation];
                        externalAccessToken = nil;
                        break;
                    default:
                        break;
                }
                
                if (error) {
                    
                    [[Analytics sharedClient] event:kAnalyticsEventLoginFailed
                                     withProperties:@{ @"from": @"Facebook",
                                                       @"code": @(error.code) }];
                    
                    failBlock(error);
                }
            }];
    
}


-(void)initOAuth2Service{
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreAccountsDidChangeNotification
                                                      object:[NXOAuth2AccountStore sharedStore]
                                                       queue:nil
                                                  usingBlock:^(NSNotification *aNotification){
                                                      if (!isLoginCompleted) {
                                                          [self finishWithAuth2Login];
                                                      }
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreDidFailToRequestAccessNotification
                                                      object:[NXOAuth2AccountStore sharedStore]
                                                       queue:nil
                                                  usingBlock:^(NSNotification *aNotification) {
                                                      NSLog(@"login failed");
                                                  }];
}


-(void)finishWithAuth2Login{
    
    NXOAuth2AccountStore *sharedStore = [NXOAuth2AccountStore sharedStore];
    BOOL loginSucceeded = NO;
    for (NXOAuth2Account *account in [sharedStore accountsWithAccountType:accountType]) {
        NSString *accessT = [[account accessToken] accessToken];
        if (accessT && [accessT length] > 0){
            iNatAccessToken = nil;
            iNatAccessToken = [NSString stringWithFormat:@"Bearer %@", accessT ];
            loginSucceeded = YES;
        }
    }
    if (loginSucceeded) {
        
        [[Analytics sharedClient] event:kAnalyticsEventLogin
                         withProperties:@{ @"Via": @"iNaturalist" }];
        isLoginCompleted = YES;
        [[NSUserDefaults standardUserDefaults] setValue:iNatAccessToken
                                                 forKey:INatTokenPrefKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        INaturalistAppDelegate *app = [[UIApplication sharedApplication] delegate];
        [app showMainUI];
        [RKClient.sharedClient setValue:iNatAccessToken forHTTPHeaderField:@"Authorization"];
        [RKClient.sharedClient setAuthenticationType:RKRequestAuthenticationTypeNone];
        [app.photoObjectManager.client setValue:iNatAccessToken forHTTPHeaderField:@"Authorization"];
        [app.photoObjectManager.client setAuthenticationType: RKRequestAuthenticationTypeNone];
        [self removeOAuth2Observers];
        
        
        [[RKClient sharedClient] get:@"/users/edit.json"
                          usingBlock:^(RKRequest *request) {
                              
                              request.onDidFailLoadWithError = ^(NSError *error) {
                                  NSLog(@"error fetching self: %@", error.localizedDescription);
                              };
                              
                              request.onDidLoadResponse = ^(RKResponse *response) {
                                  NSError *error = nil;
                                  id parsedData = [NSJSONSerialization JSONObjectWithData:response.body
                                                                                  options:NSJSONReadingAllowFragments
                                                                                    error:&error];
                                  if (error) {
                                      NSLog(@"error parsing json: %@", error.localizedDescription);
                                  }
                                  
                                  NSString *userName = [parsedData objectForKey:@"login"];
                                  [[NSUserDefaults standardUserDefaults] setValue:userName
                                                                           forKey:INatUsernamePrefKey];
                                  
                                  [[NSUserDefaults standardUserDefaults] setValue:iNatAccessToken
                                                                           forKey:INatTokenPrefKey];
                                  [[NSUserDefaults standardUserDefaults] synchronize];
                                  
                                  [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoggedInNotificationName
                                                                                      object:nil];
                              };
                          }];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoggedInNotificationName
                                                            object:nil];
    } else {
        [[Analytics sharedClient] event:kAnalyticsEventLoginFailed
                         withProperties:@{ @"from": @"iNaturalist" }];
        NSLog(@"login failed");
    }
}

-(void) removeOAuth2Observers{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NXOAuth2AccountStoreAccountsDidChangeNotification object:[NXOAuth2AccountStore sharedStore]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NXOAuth2AccountStoreDidFailToRequestAccessNotification object:[NXOAuth2AccountStore sharedStore]];
}

#pragma mark - Google methods

- (NSString *)scopesForGoogleSignin {
    GPPSignIn *signin = [GPPSignIn sharedInstance];
    
    // GTMOAuth2VCTouch takes a different scope format than GPPSignIn
    // @"plus.login plus.me userinfo.email"
    __block NSString *scopes;
    [signin.scopes enumerateObjectsUsingBlock:^(NSString *scope, NSUInteger idx, BOOL *stop) {
        if (idx == 0)
            scopes = [NSString stringWithString:scope];
        else
            scopes = [scopes stringByAppendingString:[NSString stringWithFormat:@" %@", scope]];
    }];
    
    return scopes;
}

- (NSString *)clientIdForGoogleSignin {
    return [[GPPSignIn sharedInstance] clientID];
}

- (GPPSignIn *)googleSignin {
    return [GPPSignIn sharedInstance];
}

-(void) initGoogleLogin{
    // Google+ init
    GPPSignIn   *googleSignIn = [GPPSignIn sharedInstance];
    googleSignIn.clientID = GoogleClientId;
    googleSignIn.scopes = [NSArray arrayWithObjects:
                           kGTLAuthScopePlusLogin, // defined in GTLPlusConstants.h
                           kGTLAuthScopePlusMe,
                           @"https://www.googleapis.com/auth/userinfo.email", nil];
    googleSignIn.delegate = self;
    [googleSignIn trySilentAuthentication];
}

- (void)viewController:(GTMOAuth2ViewControllerTouch *)vc
          finishedAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error {
    
    if (error || (!auth.accessToken && tryingGoogleReauth)) {
        NSString *msg = error.localizedDescription;
        if (!msg) {
            msg = NSLocalizedString(@"Google sign in failed", nil);
        }
        
        [[Analytics sharedClient] event:kAnalyticsEventLoginFailed
                         withProperties:@{ @"from": @"Google" }];
        
        tryingGoogleReauth = NO;
        
    } else if (!auth.accessToken && !tryingGoogleReauth) {
        tryingGoogleReauth = YES;
        [[GPPSignIn sharedInstance] signOut];
        [self initGoogleLogin];
        
    } else {
        [[Analytics sharedClient] event:kAnalyticsEventLogin
                         withProperties:@{ @"Via": @"Google+" }];
        externalAccessToken = [[auth accessToken] copy];
        accountType = nil;
        accountType = kINatAuthServiceExtToken;
        [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:accountType
                                                             assertionType:[NSURL URLWithString:@"http://google.com"]
                                                                 assertion:externalAccessToken];
        tryingGoogleReauth = NO;
        
        [((INaturalistAppDelegate *)[UIApplication sharedApplication].delegate) showMainUI];
        [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoggedInNotificationName
                                                            object:nil];
        [vc dismissViewControllerAnimated:YES completion:nil];
    }
}




@end
