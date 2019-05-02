//
//  LoginController.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/15/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <NXOAuth2Client/NXOAuth2.h>
#import <GoogleSignIn/GoogleSignIn.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <JWT/JWT.h>
#import <GTMOAuth2/GTMOAuth2ViewControllerTouch.h>

#import "LoginController.h"
#import "Analytics.h"
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

static const NSTimeInterval LocalMeUserValidTimeInterval = 600;

@interface LoginController () <GIDSignInDelegate> {
    NSString    *externalAccessToken;
    NSString    *iNatAccessToken;
    NSString    *accountType;
    BOOL        isLoginCompleted;
    NSInteger   lastAssertionType;
}
@end

#pragma mark - NSNotification names

NSString *INatJWTFailureErrorDomain = @"org.inaturalist.jwtfailure";
NSString *kUserLoggedInNotificationName = @"UserLoggedInNotificationName";
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
    self.jwtToken = nil;
    self.jwtTokenExpiration = nil;
}

#pragma mark - Facebook

- (void)loginButton:(FBSDKLoginButton *)loginButton didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result error:(NSError *)error {
    
    if (error || !result.token) {
        [[Analytics sharedClient] event:kAnalyticsEventLoginFailed
                         withProperties:@{ @"Via": @"Facebook" }];
        [self.delegate loginFailedWithError:error];
    } else {
        [[Analytics sharedClient] event:kAnalyticsEventLogin
                         withProperties:@{ @"Via": @"Facebook" }];
        externalAccessToken = [[result.token tokenString] copy];
        accountType = kINatAuthServiceExtToken;
        [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:accountType
                                                             assertionType:[NSURL URLWithString:@"http://facebook.com"]
                                                                 assertion:externalAccessToken];
    }
}

- (void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton {
    // do nothing
    // seem to need to
}

#pragma mark - INat OAuth Login

- (void)createAccountWithEmail:(NSString *)email
                      password:(NSString *)password
                      username:(NSString *)username
                          site:(NSInteger)siteId
                       license:(NSString *)license {
    
    NSString *localeString = [[NSLocale currentLocale] localeIdentifier];
    // format for rails
    localeString = [localeString stringByReplacingOccurrencesOfString:@"_" withString:@"-"];
    // default to english
    if (!localeString) { localeString = @"en-US"; }
    
    [[Analytics sharedClient] debugLog:@"Network - Post Users"];
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
                                              @"user[locale]": localeString,
                                              };
                           
                           request.onDidLoadResponse = ^(RKResponse *response) {
                               NSError *error = nil;
                               id respJson = [NSJSONSerialization JSONObjectWithData:response.body
                                                                             options:NSJSONReadingAllowFragments
                                                                               error:&error];
                               
                               if (error) {
                                   [self.delegate loginFailedWithError:error];
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
                                   [self.delegate loginFailedWithError:newError];
                                   return;
                               }

                               [[Analytics sharedClient] event:kAnalyticsEventSignup];
                               
                               [self loginWithUsername:username
                                              password:password];
                               
                           };
                           
                           request.onDidFailLoadWithError = ^(NSError *error) {
                               [self.delegate loginFailedWithError:error];
                           };
                       }];
}

- (void)loginWithUsername:(NSString *)username
                 password:(NSString *)password {
    
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
                                                          [self.delegate loginFailedWithError:err];
                                                      } else {
                                                          [self.delegate loginFailedWithError:nil];
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
        if ([accountType isEqualToString:kINatAuthService]) {
            [[Analytics sharedClient] event:kAnalyticsEventLogin
                             withProperties:@{ @"Via": @"iNaturalist" }];
        }
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
        
        // because we're in the midst of switching the default URL, and adding access tokens,
        // we can't seem to make an object loader fetch here. so instead we do the ugly GET
        // and do the User object mapping manually. admittedly not ideal, and worth another
        // look when we upgrade to RK 0.2x
        [[Analytics sharedClient] debugLog:@"Network - Get Me User"];
        [[RKClient sharedClient] get:@"/users/edit.json"
                          usingBlock:^(RKRequest *request) {
                              
                              request.onDidFailLoadWithError = ^(NSError *error) {
                                  [[Analytics sharedClient] event:kAnalyticsEventLoginFailed
                                                   withProperties:@{ @"from": @"iNaturalist",
                                                                     @"error": error.localizedDescription,
                                                                     }];
                                  
                                  [self.delegate loginFailedWithError:error];
                              };
                              
                              request.onDidLoadResponse = ^(RKResponse *response) {
                                  NSError *error = nil;
                                  id parsedData = [NSJSONSerialization JSONObjectWithData:response.body
                                                                                  options:NSJSONReadingAllowFragments
                                                                                    error:&error];
                                  if (error) {
                                      [[Analytics sharedClient] event:kAnalyticsEventLoginFailed
                                                       withProperties:@{ @"from": @"iNaturalist",
                                                                         @"error": error.localizedDescription,
                                                                         }];

                                      [self.delegate loginFailedWithError:error];
                                  } else if (!parsedData) {
                                      [[Analytics sharedClient] event:kAnalyticsEventLoginFailed
                                                       withProperties:@{ @"from": @"iNaturalist",
                                                                         @"error": @"no data from server",
                                                                         }];
                                      
                                      [self.delegate loginFailedWithError:nil];
                                  } else {
                                      ExploreUserRealm *me = [[ExploreUserRealm alloc] init];
                                      me.login = [parsedData objectForKey:@"login"] ?: @"";
                                      me.email = [parsedData objectForKey:@"email"];
                                      me.userIconString = [parsedData objectForKey:@"user_icon_url"];
                                      me.userId = [[parsedData objectForKey:@"id"] integerValue];
                                      me.observationsCount = [[parsedData objectForKey:@"observations_count"] integerValue];
                                      me.siteId = [[parsedData objectForKey:@"site_id"] integerValue];
                                      me.syncedAt = [NSDate distantPast];
                                      
                                      RLMRealm *realm = [RLMRealm defaultRealm];
                                      [realm beginWriteTransaction];
                                      [realm addOrUpdateObject:me];
                                      [realm commitWriteTransaction];
                                      
                                      NSString *identifier = [NSString stringWithFormat:@"%ld", (long)me.userId];
                                      [[Analytics sharedClient] registerUserWithIdentifier:identifier];
                                      
                                      [[NSUserDefaults standardUserDefaults] setValue:@(me.userId)
                                                                               forKey:kINatUserIdPrefKey];
                                      [[NSUserDefaults standardUserDefaults] setValue:iNatAccessToken
                                                                               forKey:INatTokenPrefKey];
                                      [[NSUserDefaults standardUserDefaults] synchronize];
                                      
                                      [self.delegate loginSuccess];
                                      
                                      [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoggedInNotificationName
                                                                                          object:nil];
                                  }
                              };
                          }];        
    } else {
        [[Analytics sharedClient] event:kAnalyticsEventLoginFailed
                         withProperties:@{ @"from": @"iNaturalist",
                                           @"error": @"no data in nxoauth store",
                                           }];
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

- (void)initGoogleLogin {
    GIDSignIn.sharedInstance.clientID = GoogleClientId;
    GIDSignIn.sharedInstance.scopes = @[
                                        @"https://www.googleapis.com/auth/userinfo.email",
                                        ];
    GIDSignIn.sharedInstance.delegate = self;
}

- (void)signIn:(GIDSignIn *)signIn
didSignInForUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
    
    if (error || !user.authentication.idToken) {
        [[Analytics sharedClient] event:kAnalyticsEventLoginFailed
                         withProperties:@{ @"Via": @"Google" }];
        [self.delegate loginFailedWithError:error];
    } else {
        [[Analytics sharedClient] event:kAnalyticsEventLogin
                         withProperties:@{ @"Via": @"Google" }];
        externalAccessToken = [user.authentication.accessToken copy];
        accountType = kINatAuthServiceExtToken;
        [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:accountType
                                                             assertionType:[NSURL URLWithString:@"http://google.com"]
                                                                 assertion:externalAccessToken];
    }
}

#pragma mark - Success / Failure helpers

/*
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
 */

#pragma mark - Partners

- (void)loggedInUserSelectedPartner:(Partner *)partner completion:(void (^)(void))completion {
    // be extremely defensive here. an invalid baseURL shouldn't be possible,
    // but if it does happen, nothing in the app will work.
    NSURL *partnerURL = partner.baseURL;
    if (!partnerURL) { return; }
    [[NSUserDefaults standardUserDefaults] setObject:partnerURL.absoluteString
                                              forKey:kInatCustomBaseURLStringKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [((INaturalistAppDelegate *)[UIApplication sharedApplication].delegate) reconfigureForNewBaseUrl];
    
    // put user object changing site id
    ExploreUserRealm *me = [self meUserLocal];
    if (!me) { return; }
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    me.siteId = partner.identifier;
    [realm commitWriteTransaction];
    
    // delete any stashed taxa from core data
    [Taxon deleteAll];
    
    NSError *saveError = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&saveError];
    if (saveError) {
        [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"error saving: %@",
                                            saveError.localizedDescription]];
    }
    
    // delete any stashed taxa from realm
    RLMResults *allExploreTaxa = [ExploreTaxonRealm allObjects];
    [realm beginWriteTransaction];
    [realm deleteObjects:allExploreTaxa];
    [realm commitWriteTransaction];
    
    // can't do this in node yet
    [[Analytics sharedClient] debugLog:@"Network - Put Me User"];
    [[RKClient sharedClient] put:[NSString stringWithFormat:@"/users/%ld", (long)me.userId]
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

#pragma mark - Convenience methods for working with the logged in User

- (void)dirtyLocalMeUser {
    ExploreUserRealm *me = [self meUserLocal];
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    me.syncedAt = [NSDate distantPast];
    [realm commitWriteTransaction];
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
    
    // if we can't find the me user in realm,
    // try to fetch from core data
    User *meFromCoreData = [self fetchMeFromCoreData];
    if (meFromCoreData) {
        ExploreUserRealm *me = [[ExploreUserRealm alloc] init];
        me.login = meFromCoreData.login;
        me.userId = meFromCoreData.recordID.integerValue;
        me.name = meFromCoreData.name;
        me.userIconString = meFromCoreData.userIconURL;
        me.email = nil;
        me.observationsCount = meFromCoreData.observationsCount.integerValue;
        me.siteId = meFromCoreData.siteId.integerValue;
        me.syncedAt = [NSDate distantPast];
        
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        [realm addOrUpdateObject:me];
        [realm commitWriteTransaction];
        
        return me;
    }
    
    return nil;
}

- (void)meUserRemoteCompletion:(void (^)(ExploreUserRealm *))completion {
    ExploreUserRealm *me = [self meUserLocal];
    if (me.syncedAt && [me.syncedAt timeIntervalSinceNow] > -LocalMeUserValidTimeInterval) {
        completion(me);
    } else {
        [[self peopleApi] fetchMeHandler:^(NSArray *results, NSInteger count, NSError *error) {
            RLMRealm *realm = [RLMRealm defaultRealm];
            [realm beginWriteTransaction];
            ExploreUserRealm *me = nil;
            for (ExploreUser *user in results) {
                me = [[ExploreUserRealm alloc] initWithMantleModel:user];
                [realm addOrUpdateObject:me];
            }
            [realm commitWriteTransaction];
            
            completion(me);
        }];
    }
}

- (User *)fetchMeFromCoreData {
	NSNumber *userId = nil;
	NSString *username = nil;
	if ([[NSUserDefaults standardUserDefaults] valueForKey:kINatUserIdPrefKey]) {
		userId = [[NSUserDefaults standardUserDefaults] valueForKey:kINatUserIdPrefKey];	
	} else {
	    username = [[NSUserDefaults standardUserDefaults] valueForKey:INatUsernamePrefKey];
	}
	
	if (userId) {
        NSFetchRequest *meFetch = [[NSFetchRequest alloc] initWithEntityName:@"User"];
        meFetch.predicate = [NSPredicate predicateWithFormat:@"recordID == %ld", (long)userId.integerValue];
        NSError *fetchError;
        User *me = [[[User managedObjectContext] executeFetchRequest:meFetch error:&fetchError] firstObject];
        if (fetchError) {
            [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"error fetching: %@",
                                                fetchError.localizedDescription]];
            return nil;
        }
        return me;
	} else if (username) {
        NSFetchRequest *meFetch = [[NSFetchRequest alloc] initWithEntityName:@"User"];
        meFetch.predicate = [NSPredicate predicateWithFormat:@"login == %@", username];
        NSError *fetchError;
        User *me = [[[User managedObjectContext] executeFetchRequest:meFetch error:&fetchError] firstObject];
        if (fetchError) {
            [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"error fetching: %@",
                                                fetchError.localizedDescription]];
            return nil;
        }
        [[NSUserDefaults standardUserDefaults] setValue:me.recordID forKey:kINatUserIdPrefKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return me;
    } else {
        return nil;
    }
}

- (BOOL)isLoggedIn {
    NSString *inatToken = [[NSUserDefaults standardUserDefaults] objectForKey:INatTokenPrefKey];
    return (inatToken && inatToken.length > 0);
}

- (void)getJWTTokenSuccess:(LoginSuccessBlock)success failure:(LoginErrorBlock)failure {
    static NSString *tokenKey = @"token";
    
    // jwt tokens expire after 30 minutes
    // if the token is more than 25 minutes old, fetch a new one
    // in case the request we're making takes a looooong time
    if (([self.jwtTokenExpiration timeIntervalSinceNow] < (25 * 60)) && self.jwtToken) {
        if (success) {
            success(@{ tokenKey: self.jwtToken });
            return;
        }
    }
    
    NSURL *url = [NSURL URLWithString:@"https://www.inaturalist.org/users/api_token.json"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    
    [request addValue:[[NSUserDefaults standardUserDefaults] stringForKey:INatTokenPrefKey]
   forHTTPHeaderField:@"Authorization"];
    
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
        } else if ([httpResponse statusCode] != 200) {
            strongSelf.jwtToken = nil;
            if (failure) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *errorDesc = nil;
                    if ([httpResponse statusCode] == 401) {
                        errorDesc = NSLocalizedString(@"You need to login to do that.",
                                                      @"401 unauthorized message");
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
                if (failure) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        failure(jsonError);
                    });
                }
            } else {
                if ([json valueForKey:@"api_token"]) {
                    strongSelf.jwtToken = [json valueForKey:@"api_token"];
                    strongSelf.jwtTokenExpiration = [NSDate date];
                    if (success) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            success(@{ tokenKey: strongSelf.jwtToken });
                        });
                    }
                } else {
                    strongSelf.jwtToken = nil;
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

- (NSString *)anonymousJWT {
    if (INatAnonymousAPISecret) {
        JWTClaimsSet *claimsSet = [[JWTClaimsSet alloc] init];
        claimsSet.expirationDate = [[NSDate date] dateByAddingTimeInterval:300];
        NSDate *expiration = [[NSDate date] dateByAddingTimeInterval:300];
        NSTimeInterval expirationStamp = [expiration timeIntervalSince1970];
        
        NSDictionary *payload = @{
                                  @"application" : @"ios",
                                  @"exp": @((NSInteger)expirationStamp),
                                  };
        id<JWTAlgorithm> algorithm = [JWTAlgorithmFactory algorithmByName:@"HS512"];
        NSString *encoded = [JWTBuilder encodePayload:payload].secret(INatAnonymousAPISecret).algorithm(algorithm).encode;
        return encoded;
    } else {
        return nil;
    }
}


@end
