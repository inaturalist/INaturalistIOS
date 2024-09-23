//
//  LoginController.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/15/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <NXOAuth2Client/NXOAuth2.h>
#import <GoogleSignIn/GoogleSignIn.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <JWT/JWT.h>
#import <SimpleKeychain/SimpleKeychain.h>

#import "LoginController.h"
#import "INaturalistAppDelegate.h"
#import "UIColor+INaturalist.h"
#import "Partner.h"
#import "User.h"
#import "UploadManager.h"
#import "Taxon.h"
#import "ExploreUser.h"
#import "PeopleAPI.h"
#import "ExploreUserRealm.h"
#import "ExploreTaxonRealm.h"
#import "NSLocale+INaturalist.h"
#import "Analytics.h"

static const NSTimeInterval LocalMeUserValidTimeInterval = 600;

@interface LoginController ()
@property NSString *externalAccessToken;
@property NSString *iNatAccessToken;
@property NSString *accountType;
@property BOOL isLoginCompleted;
@property dispatch_group_t jwtTokenRequestGroup;
@end

#pragma mark - NSNotification names

NSString *INatJWTFailureErrorDomain = @"org.inaturalist.jwtfailure";
NSString *kUserLoggedInNotificationName = @"UserLoggedInNotificationName";
NSString *kUserLoggedOutNotificationName = @"UserLoggedOutNotificationName";
NSInteger INatMinPasswordLength = 6;

@implementation LoginController

- (instancetype)init {
    if (self = [super init]) {
        self.uploadManager = [[UploadManager alloc] init];
        
        [self initOAuth2Service];
        [self initGoogleLogin];
    }
    
    return self;
}

- (PeopleAPI *)peopleApi {
    static PeopleAPI *_api = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _api = [[PeopleAPI alloc] init];
    });
    return _api;
}

- (void)logout {
    self.isLoginCompleted = NO;
    self.jwtToken = nil;
    
    self.externalAccessToken = nil;
    self.iNatAccessToken = nil;
    self.accountType = nil;
    
    [[A0SimpleKeychain keychain] deleteEntryForKey:INatJWTPrefKey];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoggedOutNotificationName
                                                        object:nil];
    
    // delete some user default objects associated with the logged in user & auth
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kINatUserIdPrefKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:INatUsernamePrefKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:INatPasswordPrefKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:INatTokenPrefKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kINatAuthServiceExtToken];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kINatAuthService];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kInatCustomBaseURLStringKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - INat OAuth Login

- (void)createAccountWithEmail:(NSString *)email
                      password:(NSString *)password
                      username:(NSString *)username
                          site:(NSInteger)siteId
                       license:(NSString *)license {

    NSString *localeString = [[NSLocale currentLocale] inat_serverFormattedLocale];

    // default to english
    if (!localeString) { localeString = @"en-US"; }

    __weak typeof(self)weakSelf = self;
    [[self peopleApi] createUserEmail:email
                                login:username
                             password:password
                               siteId:siteId
                              license:license
                            localeStr:localeString
                              handler:^(NSArray *results, NSInteger count, NSError *error) {
        
        if (error) {
            [weakSelf.delegate loginFailedWithError:error];
        } else {
            id json = results.firstObject;
            // require an ID response from the user
            if (json && [json valueForKey:@"id"]) {
                ExploreUserRealm *me = [ExploreUserRealm new];
                me.userId = [[json valueForKey:@"id"] integerValue];
                me.login = username;
                me.email = email;
                me.observationsCount = 0;
                me.siteId = siteId;
                me.syncedAt = [NSDate date];
                
                RLMRealm *realm = [RLMRealm defaultRealm];
                [realm beginWriteTransaction];
                [realm addOrUpdateObject:me];
                [realm commitWriteTransaction];
                
                // we have a me user, stash the userid in userdefaults
                [[NSUserDefaults standardUserDefaults] setValue:@(me.userId)
                                                         forKey:kINatUserIdPrefKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                // login to fetch an authtoken
                [weakSelf loginWithUsername:username
                                   password:password];
            } else {
                [weakSelf.delegate loginFailedWithError:nil];
            }
            
        }

    }];    
}

- (void)loginWithUsername:(NSString *)username
                 password:(NSString *)password {
    
    self.accountType = kINatAuthService;
    self.isLoginCompleted = NO;
    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:self.accountType
                                                              username:username
                                                              password:password];
}

-(void)initOAuth2Service{
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreAccountsDidChangeNotification
                                                      object:[NXOAuth2AccountStore sharedStore]
                                                       queue:nil
                                                  usingBlock:^(NSNotification *aNotification){
        if (!self.isLoginCompleted) {
            [self finishWithAuth2Login];
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreDidFailToRequestAccessNotification
                                                      object:[NXOAuth2AccountStore sharedStore]
                                                       queue:nil
                                                  usingBlock:^(NSNotification *aNotification) {
                                                      id err = [aNotification.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
                                                      if (err && [err isKindOfClass:[NSError class]]) {
                                                          [self.delegate loginFailedWithError:err];
                                                      } else {
                                                          [self.delegate loginFailedWithError:nil];
                                                      }
                                                  }];
}


-(void)finishWithAuth2Login {
    NXOAuth2AccountStore *sharedStore = [NXOAuth2AccountStore sharedStore];
    BOOL loginSucceeded = NO;
    for (NXOAuth2Account *account in [sharedStore accountsWithAccountType:self.accountType]) {
        NSString *accessT = [[account accessToken] accessToken];
        if (accessT && [accessT length] > 0){
            self.iNatAccessToken = nil;
            self.iNatAccessToken = [NSString stringWithFormat:@"Bearer %@", accessT ];
            loginSucceeded = YES;
        }
    }
    
    if (loginSucceeded) {
        self.isLoginCompleted = YES;
        [[NSUserDefaults standardUserDefaults] setValue:self.iNatAccessToken
                                                 forKey:INatTokenPrefKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        
        if (self.meUserLocal) {
            // we've already got a me user, so this was a create account
            // via the iNat auth service. wrap up the oauth stuff and update
            // the UI
            [self removeOAuth2Observers];
            [self.delegate loginSuccess];
            [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoggedInNotificationName
                                                                object:nil];
        } else {
            __weak typeof(self) weakSelf = self;
            // shared callback handler
            INatAPIFetchCompletionCountHandler handler = ^(NSArray *results, NSInteger count, NSError *error) {
                if (error) {
                    [weakSelf.delegate loginFailedWithError:error];
                } else if (results.count != 1) {
                    [weakSelf.delegate loginFailedWithError:nil];
                } else {
                    ExploreUserRealm *me = [[ExploreUserRealm alloc] initWithMantleModel:results.firstObject];
                    me.syncedAt = [NSDate date];
                    
                    RLMRealm *realm = [RLMRealm defaultRealm];
                    [realm beginWriteTransaction];
                    [realm addOrUpdateObject:me];
                    [realm commitWriteTransaction];
                    
                    // we have a me user, stash the userid in userdefaults
                    [[NSUserDefaults standardUserDefaults] setValue:@(me.userId)
                                                             forKey:kINatUserIdPrefKey];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    
                    [weakSelf removeOAuth2Observers];
                    [weakSelf.delegate loginSuccess];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoggedInNotificationName
                                                                        object:nil];
                }
            };
            
            if ([self.accountType isEqualToString:kINatAuthService]) {
                // if the account was a new account made via create,
                // we would already have the me user object stored
                // via the responses. so this is a login, and we can
                // fetch the user right away
                [[self peopleApi] fetchMeHandler:handler];
            } else {
                // either a login or create account via social media,
                // no way to know. we need to delay for a few seconds
                // due to indexing delays when creating new accounts
                [self.delegate delayForSettingUpAccount];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[self peopleApi] fetchMeHandler:handler];
                });
            }
        }
    } else {
        [self.delegate loginFailedWithError:nil];
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

- (void)loginWithGoogleWithPresentingVC:(UIViewController *)presentingVC {
    GIDConfiguration *config = [[GIDConfiguration alloc] initWithClientID:GoogleClientId];
    
    [GIDSignIn.sharedInstance signInWithConfiguration:config
                             presentingViewController:presentingVC
                                             callback:^(GIDGoogleUser * _Nullable user, NSError * _Nullable error) {
        
        if (error || !user.authentication.idToken) {
            [self.delegate loginFailedWithError:error];
        } else {
            self.externalAccessToken = [user.authentication.accessToken copy];
            self.accountType = kINatAuthServiceExtToken;
            [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:self.accountType
                                                                 assertionType:[NSURL URLWithString:@"http://google.com"]
                                                                     assertion:self.externalAccessToken];
            
        }
    }];
}

- (void)initGoogleLogin {
    
}

- (void)signIn:(GIDSignIn *)signIn
didSignInForUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
    
    if (error || !user.authentication.idToken) {
        [self.delegate loginFailedWithError:error];
    } else {
        self.externalAccessToken = [user.authentication.accessToken copy];
        self.accountType = kINatAuthServiceExtToken;
        [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:self.accountType
                                                             assertionType:[NSURL URLWithString:@"http://google.com"]
                                                                 assertion:self.externalAccessToken];
    }
}

#pragma mark - Apple Sign In methods

- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithError:(NSError *)error  API_AVAILABLE(ios(13.0)) {
    [self.delegate loginFailedWithError:error];
}

- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithAuthorization:(ASAuthorization *)authorization  API_AVAILABLE(ios(13.0)) {
    
    if ([authorization.credential isKindOfClass:ASAuthorizationAppleIDCredential.class]) {

        ASAuthorizationAppleIDCredential *credential = (ASAuthorizationAppleIDCredential *)authorization.credential;
        
        NSData *identityTokenData = credential.identityToken;
        NSString *identityToken = [[NSString alloc] initWithData:identityTokenData
                                                        encoding:NSUTF8StringEncoding];
        NSMutableDictionary *assertionDict = [NSMutableDictionary dictionaryWithObject:identityToken
                                                                                forKey:@"id_token"];
        
        NSPersonNameComponentsFormatter *formatter = [[NSPersonNameComponentsFormatter alloc] init];
        formatter.style = NSPersonNameComponentsFormatterStyleDefault;
        NSString *nameString = [formatter stringFromPersonNameComponents:credential.fullName];
        
        if (nameString) {
            assertionDict[@"name"] = nameString;
        }
        
        NSError *jsonError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:assertionDict
                                                           options:0
                                                             error:&jsonError];
        NSString *assertionJSON = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        self.externalAccessToken = [identityToken copy];
        self.accountType = kINatAuthServiceExtToken;
        [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:self.accountType
                                                             assertionType:[NSURL URLWithString:@"https://appleid.apple.com"]
                                                                 assertion:assertionJSON];
    }
}

#pragma mark - Partners

- (void)loggedInUserSelectedPartner:(Partner *)partner completion:(void (^)(void))completion {
    // be extremely defensive here. an invalid baseURL shouldn't be possible,
    // but if it does happen, nothing in the app will work.
    NSURL *partnerURL = partner.baseURL;
    if (!partnerURL) { return; }
    [[NSUserDefaults standardUserDefaults] setObject:partnerURL.absoluteString
                                              forKey:kInatCustomBaseURLStringKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // put user object changing site id
    ExploreUserRealm *me = [self meUserLocal];
    if (!me) { return; }
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    me.siteId = partner.identifier;
    [realm commitWriteTransaction];
        
    // delete any stashed taxa from realm
    RLMResults *allTaxa = [ExploreTaxonRealm allObjects];
    [realm beginWriteTransaction];
    [realm deleteObjects:allTaxa];
    [realm commitWriteTransaction];
    
    // send this to the server
    [[self peopleApi] setSiteId:partner.identifier forUserId:me.userId handler:^(NSArray *results, NSInteger count, NSError *error) {
        if (completion) {
            completion();
        }
    }];
}

#pragma mark - Convenience methods for working with the logged in User

- (void)dirtyLocalMeUser {
    ExploreUserRealm *me = [self meUserLocal];
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    me.syncedAt = [NSDate distantPast];
    [realm commitWriteTransaction];
}

- (NSInteger)meUserId {
    return [[[NSUserDefaults standardUserDefaults] valueForKey:kINatUserIdPrefKey] intValue];
}

- (ExploreUserRealm *)meUserLocal {
    NSNumber *userId = nil;
    NSString *username = nil;
    if ([[NSUserDefaults standardUserDefaults] valueForKey:kINatUserIdPrefKey]) {
        userId = [[NSUserDefaults standardUserDefaults] valueForKey:kINatUserIdPrefKey];
    } else {
        username = [[NSUserDefaults standardUserDefaults] valueForKey:INatUsernamePrefKey];
    }
    
    if (userId) {
        ExploreUserRealm *me = [ExploreUserRealm objectForPrimaryKey:userId];
        if (me) {
            return me;
        }
    } else if (username) {
        ExploreUserRealm *me = [[ExploreUserRealm objectsWhere:@"login == %@", username] firstObject];
        if (me) {
            [[NSUserDefaults standardUserDefaults] setValue:@(me.userId) forKey:kINatUserIdPrefKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            return me;
        }
    }

    return nil;
}

- (void)meUserRemoteCompletion:(void (^)(ExploreUserRealm *))completion {
    ExploreUserRealm *me = [self meUserLocal];
    if (me.syncedAt && ([me.syncedAt timeIntervalSinceNow] > -LocalMeUserValidTimeInterval)) {
        completion(me);
    } else {
        [[self peopleApi] fetchMeHandler:^(NSArray *results, NSInteger count, NSError *error) {
            // results firstobject should contain a prefersNoTracking variable
            // we don't stash this on the realm user because it'll get clobbered when
            // the user is fetched in other contexts and in those contexts, these value
            // aren't returned by the server.
            // we'll also stash some other variables for user preferences around common
            // names and such
            if (results.firstObject) {
                ExploreUser *euMe = results.firstObject;
                [[NSUserDefaults standardUserDefaults] setBool:euMe.prefersNoTracking
                                                        forKey:kINatPreferNoTrackPrefKey];
                [[NSUserDefaults standardUserDefaults] setBool:euMe.showCommonNames
                                                        forKey:kINatShowCommonNamesPrefKey];
                [[NSUserDefaults standardUserDefaults] setBool:euMe.showScientificNamesFirst
                                                        forKey:kINatShowScientificNamesFirstPrefKey];

                // just in case, don't ever try to stash a garbage me user id
                if (euMe.userId > 0) {
                    // we have a me user, stash the userid in userdefaults
                    [[NSUserDefaults standardUserDefaults] setValue:@(euMe.userId)
                                                             forKey:kINatUserIdPrefKey];
                }

                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
            // stash the already joined projects so we can add them to the fetched user
            ExploreUserRealm *localMe = [self meUserLocal];
            RLMArray<ExploreProjectRealm> *joinedProjects = localMe.joinedProjects;
            
            RLMRealm *realm = [RLMRealm defaultRealm];
            [realm beginWriteTransaction];
            ExploreUserRealm *me = nil;
            for (ExploreUser *user in results) {
                NSDictionary *value = [ExploreUserRealm valueForMantleModel:user];
                me = [[ExploreUserRealm alloc] initWithValue:value];
                me.joinedProjects = joinedProjects;
                [realm addOrUpdateObject:me];
            }
            [realm commitWriteTransaction];

            completion(me);
        }];
    }
}

- (BOOL)isLoggedIn {
    NSString *inatToken = [[NSUserDefaults standardUserDefaults] objectForKey:INatTokenPrefKey];
    return (inatToken && inatToken.length > 0);
}

- (void)getJWTTokenSuccess:(LoginSuccessBlock)success failure:(LoginErrorBlock)failure {
    static NSString *tokenKey = @"token";
    
    // If we don't have a JWT currently, check the user's keychain for one before proceeding to fetch a new one
    if (!self.jwtToken) {
        self.jwtToken = [[A0SimpleKeychain keychain] stringForKey:INatJWTPrefKey];
    }
    
    // if the JWT will expire within the next 30 seconds, re-fetch it first
    // note: if self.jwtTokenExpiration fails to extract for any reason, it will be nil,
    // so this check will fail and the JWT will be re-fetched
    
    // jwtexpiration timeIntervalSinceNow starts at 86400 and decrements down to zero
    // eventually becoming negative. refetch if it's less than 30 seconds from now.
    if (self.jwtToken && [self.jwtTokenExpiration timeIntervalSinceNow] > 30) {
        if (success) {
            success(@{ tokenKey: self.jwtToken });
        }
        return;
    }
    
    if (self.jwtTokenRequestGroup) {
        dispatch_group_notify(self.jwtTokenRequestGroup, dispatch_get_main_queue(), ^{
            if (self.jwtToken && success) {
                success(@{ tokenKey: self.jwtToken});
            }
        });
        return;
    }
    
    self.jwtTokenRequestGroup = dispatch_group_create();
    dispatch_group_enter(self.jwtTokenRequestGroup);
    
    NSURL *url = [NSURL URLWithString:@"https://www.inaturalist.org/users/api_token.json"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    
    [request addValue:[[NSUserDefaults standardUserDefaults] stringForKey:INatTokenPrefKey]
   forHTTPHeaderField:@"Authorization"];
    [request addValue:[[Analytics sharedClient] installationId]
   forHTTPHeaderField:@"X-Installation-ID"];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    __weak typeof(self)weakSelf = self;
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if (error) {
            if (failure) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(error);
                });
            }
            strongSelf.jwtToken = nil;
            dispatch_group_leave(strongSelf.jwtTokenRequestGroup);
            strongSelf.jwtTokenRequestGroup = NULL;
        } else if ([httpResponse statusCode] != 200) {
            strongSelf.jwtToken = nil;
            dispatch_group_leave(strongSelf.jwtTokenRequestGroup);
            strongSelf.jwtTokenRequestGroup = NULL;
            if (failure) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *errorDesc = nil;
                    if ([httpResponse statusCode] == 401) {
                        if (strongSelf.isLoggedIn) {
                            errorDesc = NSLocalizedString(@"Your login credentials appear to have changed. Please go to Settings to sign out and then sign in again.",
                                                          @"401 unauthorized message when signed in");
                        } else {
                            errorDesc = NSLocalizedString(@"You need to log in to do that.",
                                                          @"401 unauthorized message when signed out");
                        }
                    } else if ([httpResponse statusCode] == 403) {
                        errorDesc = NSLocalizedString(@"You don't have permission to do that. Your account may have been suspended. Please contact help@inaturalist.org",
                                                      @"403 forbidden message");
                    } else {
                        errorDesc = NSLocalizedString(@"Unknown error", nil);
                    }
                    NSDictionary *info = @{
                                           NSLocalizedDescriptionKey: errorDesc
                                           };
                    NSError *error = [NSError errorWithDomain:@"org.inaturalist.ios"
                                                         code:[httpResponse statusCode]
                                                     userInfo:info];
                    failure(error);
                });
            }
        } else {
            NSError *jsonError = nil;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
            if (jsonError) {
                strongSelf.jwtToken = nil;
                dispatch_group_leave(strongSelf.jwtTokenRequestGroup);
                strongSelf.jwtTokenRequestGroup = NULL;
                if (failure) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        failure(jsonError);
                    });
                }
            } else {
                if ([json valueForKey:@"api_token"]) {
                    NSString *jwt = [json valueForKey:@"api_token"];
                    strongSelf.jwtToken = jwt;
                    [[A0SimpleKeychain keychain] setString:jwt forKey:INatJWTPrefKey];
                    dispatch_group_leave(strongSelf.jwtTokenRequestGroup);
                    strongSelf.jwtTokenRequestGroup = NULL;
                    if (success) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            success(@{ tokenKey: jwt });
                        });
                    }
                } else {
                    strongSelf.jwtToken = nil;
                    dispatch_group_leave(strongSelf.jwtTokenRequestGroup);
                    strongSelf.jwtTokenRequestGroup = NULL;
                    if (failure) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            failure(nil);
                        });
                    }
                }
            }
        }
    }] resume];
}

- (NSDate *)jwtTokenExpiration {
    if (!self.jwtToken) {
        return nil;
    }
    
    NSArray *jwtParts = [self.jwtToken componentsSeparatedByString:@"."];
    if (jwtParts.count != 3) {
        // invalid JWT
        return nil;
    }
    NSString *payload = jwtParts[1];
    
    // jwt payload is base64 encoded json
    NSData *data = [[NSData alloc] initWithBase64EncodedString:payload options:0];
    if (!data) {
        // payload is invalid base64
        return nil;
    }
    
    // now get the json inside the data
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data
                                                         options:NSJSONReadingAllowFragments
                                                           error:&error];
    if (error || !dict) {
        return nil;
    }
    
    if (dict[@"exp"] == nil || [dict[@"exp"] doubleValue] == 0) {
        return nil;
    }
    
    return [NSDate dateWithTimeIntervalSince1970:[dict[@"exp"] doubleValue]];
}

- (NSString *)anonymousJWT {
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
