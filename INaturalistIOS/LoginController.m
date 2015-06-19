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
#import "UIColor+INaturalist.h"
#import "Partner.h"
#import "User.h"


@interface LoginController () <GPPSignInDelegate> {
    NSString    *externalAccessToken;
    NSString    *iNatAccessToken;
    NSString    *accountType;
    BOOL        isLoginCompleted;
    NSInteger   lastAssertionType;
    BOOL        tryingGoogleReauth;
}
@property (atomic, readwrite, copy) LoginSuccessBlock currentSuccessBlock;
@property (atomic, readwrite, copy) LoginErrorBlock currentErrorBlock;

@end

#pragma mark - NSNotification names

NSString *kUserLoggedInNotificationName = @"UserLoggedInNotificationName";
NSInteger INatMinPasswordLength = 6;

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

#pragma mark - Facebook

- (void)loginWithFacebookSuccess:(LoginSuccessBlock)successBlock
                         failure:(LoginErrorBlock)errorBlock {
    
    self.currentSuccessBlock = successBlock;
    self.currentErrorBlock = errorBlock;
    
    NSArray *perms = @[@"email", @"offline_access", @"user_photos", @"friends_photos", @"user_groups"];
    FBSession *session = [[FBSession alloc] initWithAppID:nil
                                              permissions:perms
                                          urlSchemeSuffix:@"inat"
                                       tokenCacheStrategy:nil];
    [FBSession setActiveSession:session];
    [session openWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent
            completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                
                if (error) {
                    [[Analytics sharedClient] event:kAnalyticsEventLoginFailed
                                     withProperties:@{ @"from": @"Facebook",
                                                       @"code": @(error.code) }];
                    
                    [self executeError:error];
                    
                    return;
                }

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
                        
                        [self executeSuccess:nil];
                        
                        break;
                    case FBSessionStateClosed:
                        NSLog(@"session FBSessionStateClosed");
                    case FBSessionStateClosedLoginFailed:
                        NSLog(@"session FBSessionStateClosedLoginFailed");
                        [FBSession.activeSession closeAndClearTokenInformation];
                        externalAccessToken = nil;
                        
                        [self executeError:nil];
                        break;
                    default:
                        break;
                }
            }];
    
}

#pragma mark - INat OAuth Login

- (void)createAccountWithEmail:(NSString *)email
                      password:(NSString *)password
                      username:(NSString *)username
                          site:(NSInteger)siteId
                       license:(NSString *)license
                       success:(LoginSuccessBlock)successBlock
                       failure:(LoginErrorBlock)errorBlock {
    
    self.currentSuccessBlock = successBlock;
    self.currentErrorBlock = errorBlock;
    
    [[RKClient sharedClient] post:@"/users.json"
                       usingBlock:^(RKRequest *request) {
                           request.params = @{
                                              @"user[email]": email,
                                              @"user[login]": username,
                                              @"user[password]": password,
                                              @"user[password_confirmation]": password,
                                              @"user[site_id]": @(siteId),
                                              @"user[preferred_observation_license]": license,
                                              @"user[preferred_photo_license]": license,
                                              @"user[preferred_sound_license]": license,
                                              };
                           
                           request.onDidLoadResponse = ^(RKResponse *response) {
                               NSError *error = nil;
                               id respJson = [NSJSONSerialization JSONObjectWithData:response.body
                                                                             options:NSJSONReadingAllowFragments
                                                                               error:&error];
                               
                               if (error) {
                                   [self executeError:error];
                                   return;
                               }
                               
                               if ([respJson valueForKey:@"errors"]) {
                                   // TODO: extract error from json and notify user
                                   NSArray *errors = [respJson valueForKey:@"errors"];
                                   NSError *newError = [NSError errorWithDomain:@"org.inaturalist"
                                                                           code:response.statusCode
                                                                       userInfo:@{
                                                                                  NSLocalizedDescriptionKey: errors.firstObject
                                                                                  }];
                                   [self executeError:newError];
                                   return;
                               }
                               
                               [self loginWithUsername:username
                                              password:password
                                               success:successBlock
                                               failure:errorBlock];
                               
                           };
                           
                           request.onDidFailLoadWithError = ^(NSError *error) {
                               [self executeError:error];
                           };
                           
                       }];
}

- (void)loginWithUsername:(NSString *)username
                 password:(NSString *)password
                  success:(LoginSuccessBlock)successBlock
                  failure:(LoginErrorBlock)errorBlock {
    
    self.currentSuccessBlock = successBlock;
    self.currentErrorBlock = errorBlock;
    
    accountType = nil;
    accountType = kINatAuthService;
    isLoginCompleted = NO;
    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:accountType
                                                              username:username
                                                              password:password];
    
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
                                                      id err = [aNotification.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
                                                      NSLog(@"err is %@", err);
                                                      if (err && [err isKindOfClass:[NSError class]]) {
                                                          [self executeError:err];
                                                      } else {
                                                          [self executeError:nil];
                                                      }
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
        
        INaturalistAppDelegate *app = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
        [RKClient.sharedClient setValue:iNatAccessToken forHTTPHeaderField:@"Authorization"];
        [RKClient.sharedClient setAuthenticationType:RKRequestAuthenticationTypeNone];
        [app.photoObjectManager.client setValue:iNatAccessToken forHTTPHeaderField:@"Authorization"];
        [app.photoObjectManager.client setAuthenticationType: RKRequestAuthenticationTypeNone];
        [self removeOAuth2Observers];
        
        [[RKClient sharedClient] get:@"/users/edit.json"
                          usingBlock:^(RKRequest *request) {
                              
                              request.onDidFailLoadWithError = ^(NSError *error) {
                                  NSLog(@"error fetching self: %@", error.localizedDescription);
                                  [self executeError:error];
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
                                  
                                  [self executeSuccess:nil];

                                  [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoggedInNotificationName
                                                                                      object:nil];
                              };
                          }];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoggedInNotificationName
                                                            object:nil];
    } else {
        [[Analytics sharedClient] event:kAnalyticsEventLoginFailed
                         withProperties:@{ @"from": @"iNaturalist" }];
        
        [self executeError:nil];
    }
}

-(void) removeOAuth2Observers{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NXOAuth2AccountStoreAccountsDidChangeNotification
                                                  object:[NXOAuth2AccountStore sharedStore]];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NXOAuth2AccountStoreDidFailToRequestAccessNotification
                                                  object:[NXOAuth2AccountStore sharedStore]];
}

#pragma mark - Google methods

- (void)loginWithGoogleUsingNavController:(UINavigationController *)nav
                                  success:(LoginSuccessBlock)success
                                  failure:(LoginErrorBlock)error {
    
    self.currentSuccessBlock = success;
    self.currentErrorBlock = error;
    
    GooglePlusAuthViewController *vc = [GooglePlusAuthViewController controllerWithScope:self.scopesForGoogleSignin
                                                                                clientID:self.clientIdForGoogleSignin
                                                                            clientSecret:nil
                                                                        keychainItemName:nil
                                                                                delegate:self
                                                                        finishedSelector:@selector(viewController:finishedAuth:error:)];
    [nav pushViewController:vc animated:YES];
    
    // inat green button tint
    [nav.navigationBar setTintColor:[UIColor inatTint]];
    
    // standard navigation bar
    [nav.navigationBar setBackgroundImage:nil
                            forBarMetrics:UIBarMetricsDefault];
    [nav.navigationBar setShadowImage:nil];
    [nav.navigationBar setTranslucent:YES];
    [nav setNavigationBarHidden:NO];
}

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

-(void) initGoogleLogin {
    // Google+ init
    GPPSignIn *googleSignIn = [GPPSignIn sharedInstance];
    googleSignIn.clientID = GoogleClientId;
    googleSignIn.scopes = @[
                            kGTLAuthScopePlusLogin, // defined in GTLPlusConstants.h
                            kGTLAuthScopePlusMe,
                            @"https://www.googleapis.com/auth/userinfo.email",
                            ];
    googleSignIn.delegate = self;
    [googleSignIn trySilentAuthentication];
}

- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth
                   error:(NSError *)error {
    
    if (error || (!auth.accessToken && tryingGoogleReauth)) {
        
        [[Analytics sharedClient] event:kAnalyticsEventLoginFailed
                         withProperties:@{ @"from": @"Google" }];
        tryingGoogleReauth = NO;
        [self executeError:error];
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
        [self executeSuccess:nil];
    }
}

- (void)viewController:(GTMOAuth2ViewControllerTouch *)vc
          finishedAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error {
    [self finishedWithAuth:auth error:error];
}

#pragma mark - Success / Failure helpers

- (void)executeSuccess:(NSDictionary *)results {
    @synchronized(self) {
        if (self.currentSuccessBlock) {
            self.currentSuccessBlock(results);
        }
        
        self.currentSuccessBlock = nil;
        self.currentErrorBlock = nil;
    }
}

- (void)executeError:(NSError *)error {
    @synchronized(self) {
        if (self.currentErrorBlock) {
            self.currentErrorBlock(error);
        }
        
        self.currentSuccessBlock = nil;
        self.currentErrorBlock = nil;
    }
}

#pragma mark - Partners

- (void)loggedInUserSelectedPartner:(Partner *)partner completion:(void (^)(void))completion {
    // be extremely defensive here. an invalid baseURL shouldn't be possible,
    // but if it does happen, nothing in the app will work.
    NSURL *partnerURL = partner.baseURL;
    if (!partner.baseURL) { return; }
    [[NSUserDefaults standardUserDefaults] setObject:partnerURL.absoluteString
                                              forKey:kInatCustomBaseURLStringKey];
    [((INaturalistAppDelegate *)[UIApplication sharedApplication].delegate) reconfigureForNewBaseUrl];
    
    // put user object changing site id
    User *me = [self fetchMe];
    if (!me) { return; }
    me.siteId = @(partner.identifier);
    
    NSError *saveError = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&saveError];
    if (saveError) {
        [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"error saving: %@",
                                            saveError.localizedDescription]];
        return;
    }
    
    [[RKClient sharedClient] put:[NSString stringWithFormat:@"/users/%ld", (long)me.recordID.integerValue]
                      usingBlock:^(RKRequest *request) {
                          request.params = @{
                                             @"user[site_id]": @(partner.identifier),
                                             };
                          request.onDidFailLoadWithError = ^(NSError *error) {
                              NSLog(@"error");
                          };
                          request.onDidLoadResponse = ^(RKResponse *response) {
                              if (completion) {
                                  completion();
                              }
                          };
                      }];
}

#pragma mark - Convenience method for fetching the logged in User

- (User *)fetchMe {
    NSString *username = [[NSUserDefaults standardUserDefaults] valueForKey:INatUsernamePrefKey];
    if (username) {
        NSFetchRequest *meFetch = [[NSFetchRequest alloc] initWithEntityName:@"User"];
        meFetch.predicate = [NSPredicate predicateWithFormat:@"login == %@", username];
        NSError *fetchError;
        User *me = [[[User managedObjectContext] executeFetchRequest:meFetch error:&fetchError] firstObject];
        if (fetchError) {
            [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"error fetching: %@",
                                                fetchError.localizedDescription]];
            return nil;
        }
        return me;
    } else {
        return nil;
    }
}

@end
