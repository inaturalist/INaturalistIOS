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
#import <GooglePlus/GPPSignIn.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <JWT/JWT.h>

#import "LoginController.h"
#import "Analytics.h"
#import "INaturalistAppDelegate.h"
#import "GooglePlusAuthViewController.h"
#import "UIColor+INaturalist.h"
#import "Partner.h"
#import "User.h"
#import "UploadManager.h"
#import "Taxon.h"

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
@property NSDate *jwtTokenExpiration;

@end

#pragma mark - NSNotification names

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

- (void)logout {
    self.jwtToken = nil;
    self.jwtTokenExpiration = nil;
}

#pragma mark - Facebook

- (void)loginWithFacebookViewController:(UIViewController *)vc
	success:(LoginSuccessBlock)successBlock
	failure:(LoginErrorBlock)errorBlock {

    self.currentSuccessBlock = successBlock;
    self.currentErrorBlock = errorBlock;
    
	FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
	[login
    logInWithReadPermissions: @[@"email"]
          fromViewController:vc
                     handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
    if (error) {
        [[Analytics sharedClient] event:kAnalyticsEventLoginFailed
                     withProperties:@{ @"from": @"Facebook",
                                       @"code": @(error.code) }];
    	errorBlock(error);
    } else if (result.isCancelled) {
    	errorBlock(nil);
    } else {
    	externalAccessToken = [[[result token] tokenString] copy];
		accountType = kINatAuthServiceExtToken;
        [[Analytics sharedClient] event:kAnalyticsEventLogin
                         withProperties:@{ @"Via": @"Facebook" }];
        [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:accountType
                                                             assertionType:[NSURL URLWithString:@"http://facebook.com"]
                                                                 assertion:externalAccessToken];
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

                               [[Analytics sharedClient] event:kAnalyticsEventSignup];
                               
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
                                  
                                  NSManagedObjectContext *context = [NSManagedObjectContext defaultContext];
                                  User *user = [[User alloc] initWithEntity:[User entity]
                                             insertIntoManagedObjectContext:context];
                                  user.login = [parsedData objectForKey:@"login"] ?: nil;
                                  user.recordID = [parsedData objectForKey:@"id"] ?: nil;
                                  user.observationsCount = [parsedData objectForKey:@"observations_count"] ?: @(0);
                                  user.identificationsCount = [parsedData objectForKey:@"identifications_count"] ?: @(0);
                                  user.siteId = [parsedData objectForKey:@"site_id"] ?: @(1);
                                  
                                  [[Analytics sharedClient] registerUserWithIdentifier:user.recordID.stringValue];
                                  
                                  NSError *saveError = nil;
                                  [[[RKObjectManager sharedManager] objectStore] save:&saveError];
                                  if (saveError) {
                                      [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"error saving: %@",
                                                                          saveError.localizedDescription]];
                                      [self executeError:saveError];
                                      return;
                                  }
                                  
                                  NSNumber *userId = user.recordID;
                                  [[NSUserDefaults standardUserDefaults] setValue:userId
                                  										   forKey:kINatUserIdPrefKey];
                                  [[NSUserDefaults standardUserDefaults] setValue:iNatAccessToken
                                                                           forKey:INatTokenPrefKey];
                                  [[NSUserDefaults standardUserDefaults] synchronize];
                                  
                                  [self executeSuccess:nil];

                                  [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoggedInNotificationName
                                                                                      object:nil];
                              };
                          }];        
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
    
    accountType = nil;
    accountType = kINatAuthServiceExtToken;
    isLoginCompleted = NO;

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

- (void)loginWithGoogleUsingViewController:(UIViewController *)parent
                                   success:(LoginSuccessBlock)success
                                   failure:(LoginErrorBlock)error {
    
    self.currentSuccessBlock = success;
    self.currentErrorBlock = error;
    
    accountType = nil;
    accountType = kINatAuthServiceExtToken;
    isLoginCompleted = NO;
    
    GooglePlusAuthViewController *vc = [GooglePlusAuthViewController controllerWithScope:self.scopesForGoogleSignin
                                                                                clientID:self.clientIdForGoogleSignin
                                                                            clientSecret:nil
                                                                        keychainItemName:nil
                                                                                delegate:self
                                                                        finishedSelector:@selector(viewController:finishedAuth:error:)];
    
    vc.rightBarButtonItem = [[UIBarButtonItem alloc] bk_initWithBarButtonSystemItem:UIBarButtonSystemItemCancel handler:^(id sender) {
        [parent dismissViewControllerAnimated:YES completion:nil];
    }];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [parent presentViewController:nav animated:YES completion:nil];
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
    if (!partnerURL) { return; }
    [[NSUserDefaults standardUserDefaults] setObject:partnerURL.absoluteString
                                              forKey:kInatCustomBaseURLStringKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [((INaturalistAppDelegate *)[UIApplication sharedApplication].delegate) reconfigureForNewBaseUrl];
    
    // put user object changing site id
    User *me = [self fetchMe];
    if (!me) { return; }
    me.siteId = @(partner.identifier);
    
    // delete any stashed taxa
    [Taxon deleteAll];
    
    NSError *saveError = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&saveError];
    if (saveError) {
        [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"error saving: %@",
                                            saveError.localizedDescription]];
        return;
    }
    
    [[Analytics sharedClient] debugLog:@"Network - Re-fetch Taxa after login"];
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:@"/taxa"
                                                    usingBlock:^(RKObjectLoader *loader) {
                                                        
                                                        loader.objectMapping = [Taxon mapping];
                                                        
                                                        loader.onDidLoadObjects = ^(NSArray *objects) {
                                                            
                                                            // update timestamps on taxa objects
                                                            NSDate *now = [NSDate date];
                                                            [objects enumerateObjectsUsingBlock:^(INatModel *o,
                                                                                                  NSUInteger idx,
                                                                                                  BOOL *stop) {
                                                                [o setSyncedAt:now];
                                                            }];
                                                            
                                                            NSError *saveError = nil;
                                                            [[[RKObjectManager sharedManager] objectStore] save:&saveError];
                                                            if (saveError) {
                                                                [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"Error saving store: %@",
                                                                                                    saveError.localizedDescription]];
                                                            }
                                                        };
                                                    }];
    
    [[Analytics sharedClient] debugLog:@"Network - Put Me User"];
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
