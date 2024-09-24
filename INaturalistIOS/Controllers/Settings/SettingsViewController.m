//
//  SettingsViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/27/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

@import MessageUI;
@import VTAcknowledgementsViewController;
@import MHVideoPhotoGallery;
@import GoogleSignIn;
@import ActionSheetPicker_3_0;
@import JDStatusBarNotification;
@import MBProgressHUD;
@import Realm;
@import SafariServices;

#import "SettingsViewController.h"
#import "Observation.h"
#import "ObservationPhoto.h"
#import "ProjectUser.h"
#import "ProjectObservation.h"
#import "Comment.h"
#import "Identification.h"
#import "NXOAuth2.h"
#import "Analytics.h"
#import "INaturalistAppDelegate.h"
#import "PartnerController.h"
#import "Partner.h"
#import "LoginController.h"
#import "UploadManager.h"
#import "PeopleAPI.h"
#import "OnboardingLoginViewController.h"
#import "ImageStore.h"
#import "INatReachability.h"
#import "AboutViewController.h"
#import "SettingsActionCell.h"
#import "SettingsSwitchCell.h"
#import "SettingsDetailTextCell.h"
#import "SettingsVersionCell.h"
#import "ExploreUserRealm.h"
#import "ExploreObservationRealm.h"
#import "PeopleRailsAPI.h"
#import "NSURL+INaturalist.h"
#import "iNaturalist-Swift.h"

typedef NS_ENUM(NSInteger, SettingsSection) {
    SettingsSectionAccount = 0,
    SettingsSectionApp,
    SettingsSectionHelp,
    SettingsSectionVersion,
    SettingsSectionDanger,
};
static const int SettingsLoggedInSectionCount = 5;
static const int SettingsLoggedOutSectionCount = 4;

typedef NS_ENUM(NSInteger, SettingsHelpCell) {
    SettingsHelpCellTutorial = 0,
    SettingsHelpCellContact,
    SettingsHelpCellReview,
    SettingsHelpCellStore,
    SettingsHelpCellDonate
};
static const int SettingsHelpRowCount = 5;

typedef NS_ENUM(NSInteger, SettingsAppCell) {
    SettingsAppCellChangeUsername = 0,
    SettingsAppCellChangeEmail,
    SettingsAppCellAutocompleteNames,
    SettingsAppCellAutomaticUpload,
    SettingsAppCellSuggestSpecies,
    SettingsAppCellShowCommonNames,
    SettingsAppCellShowScientficNamesFirst,
    SettingsAppCellPreferNoTracking,
    SettingsAppCellNetwork
};
static const int SettingsAppRowCount = 9;

typedef NS_ENUM(NSInteger, SettingsAccountCell) {
    SettingsAccountCellUsername,
    SettingsAccountCellEmail,
    SettingsAccountCellAction
};

typedef NS_ENUM(NSInteger, SettingsDangerCell) {
    SettingsDangerCellDeleteAccount
};


static const int SettingsAccountRowCountLoggedIn = 3;
static const int SettingsAccountRowCountLoggedOut = 1;
static const int SettingsVersionRowCount = 1;
static const int SettingsDangerRowCount = 1;

static NSString * const LastChangedPartnerDateKey = @"org.inaturalist.lastChangedPartnerDateKey";
static const int ChangePartnerMinimumInterval = 86400;

@interface SettingsViewController () <MFMailComposeViewControllerDelegate>
@property PartnerController *partnerController;
@end

@implementation SettingsViewController

- (PeopleAPI *)peopleApi {
    static PeopleAPI *_api = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _api = [[PeopleAPI alloc] init];
    });
    return _api;
}

- (PeopleRailsAPI *)peopleRailsApi {
    static PeopleRailsAPI *_api = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _api = [[PeopleRailsAPI alloc] init];
    });
    return _api;
}


#pragma mark - UI helpers

- (void)presentSignup {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Onboarding" bundle:nil];
    OnboardingLoginViewController *login = [storyboard instantiateViewControllerWithIdentifier:@"onboarding-login"];
    login.skippable = NO;
    [self presentViewController:login animated:YES completion:nil];
}

- (void)networkUnreachableAlert
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                                                   message:NSLocalizedString(@"Try again next time you're connected to the Internet.",nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                             style:UIAlertActionStyleDefault
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.partnerController = [[PartnerController alloc] init];
    
    self.title = NSLocalizedString(@"Settings", @"Title for the settings screen.");
    
    NSString *aboutTitle = NSLocalizedString(@"About", @"About button title in Settings");
    UIBarButtonItem *aboutButton = [[UIBarButtonItem alloc] initWithTitle:aboutTitle
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(launchCredits)];
    self.navigationItem.rightBarButtonItem = aboutButton;
    
    // fetch the me user from the server to populate login and email address fields
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    LoginController *login = appDelegate.loginController;
    if (login.isLoggedIn && [[INatReachability sharedClient] isNetworkReachable]) {
        // settings screen wants the most current me user since we show relevant
        // preferences & such that aren't fetched by the me user in other contexts
        // (like attached to my observations)
        [login dirtyLocalMeUser];

        __weak typeof(self)weakSelf = self;
        [login meUserRemoteCompletion:^(ExploreUserRealm *me) {
            [weakSelf.tableView reloadData];
        }];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    
    // don't show a toolbar in Settings
    [self.navigationController setToolbarHidden:YES];
}


#pragma mark - Settings Event Actions target

- (void)tappedEmail {
    if ([[INatReachability sharedClient] isNetworkReachable]) {
        NSString *title = NSLocalizedString(@"Change email address?",nil);
        NSString *msg = NSLocalizedString(@"Are you really sure?",
                                          nil);
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:msg
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
            ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
            textField.text = me.email;
        }];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Change Email", nil)
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                    UITextField *field = [alert.textFields firstObject];
                                                    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
                                                    ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
                                                    if (![me.login isEqualToString:field.text]) {
                                                        [self changeEmailTo:(NSString *)field.text];
                                                    }
                                                }]];
        
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        [self networkUnreachableAlert];
    }

}

- (void)tappedUsername {
    if ([[INatReachability sharedClient] isNetworkReachable]) {
        NSString *title = NSLocalizedString(@"Change username?",nil);
        NSString *msg = NSLocalizedString(@"Are you really sure?",
                                          nil);
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:msg
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
            ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
            textField.text = me.login;
        }];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Change Username", nil)
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                    UITextField *field = [alert.textFields firstObject];
                                                    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
                                                    ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
                                                    if (![me.login isEqualToString:field.text]) {
                                                        [self changeUsernameTo:(NSString *)field.text];
                                                    }
                                                }]];
        
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        [self networkUnreachableAlert];
    }
}

- (void)presentDeleteAccountConfirmation {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    ExploreUserRealm *me = [appDelegate.loginController meUserLocal];

    NSString *title = NSLocalizedString(@"Are you sure?",nil);
    NSString *msg = [NSString stringWithFormat: NSLocalizedString(@"By deleting your account you will remove all of your observations, all of the identifications that you've added to the observations of others, and all comments that you've made. Furthermore, this action cannot be undone. If you change your mind later, you aren't getting any of that content back. If this site generates too many notifications, consider editing your settings to opt out of certain notifications or stop receiving email from us. If you're having trouble with a specific person on the site, consider muting them instead of deleting your account. If you are deleting your account because you tried to delete some of your content but you could still see it on a map or elsewhere on the Internet, keep in mind that map data may be cached for up to a day even after records are deleted, and that deleting content on this platform may not have any effect on copies that exist on other sites and platforms (like GBIF). If you're still sure you want to delete your account, enter '%@' in the form below and click the button to delete your account and all your data.",  @"delete account confirmation"), me.login];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:msg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        
    }];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",nil)
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Delete Account", nil)
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * _Nonnull action) {
        
        NSString *confirmationCode = me.login;
        NSString *confirmation = alert.textFields.firstObject.text;
        
        if ([confirmation isEqualToString:confirmationCode]) {
            [[self peopleRailsApi] deleteAccountForUserId:me.userId
                                         confirmationCode:confirmationCode
                                             confirmation:confirmation
                                                     done:^(NSArray *results, NSInteger count, NSError *error) {
                
                NSString *alertTitle = NSLocalizedString(@"Your account has been deleted.", @"account deletion confirmation msg");
                NSString *alertMsg = @"";
                
                
                if (error) {
                    // http status code 204 is technically success but it's treated as an error in the api
                    // client (since we normally need a response), so handle it here
                    if ([error.domain isEqualToString: @"org.inaturalist.rails.http"] && error.code == 204) {
                        [self signOut];
                    } else {
                        alertTitle = NSLocalizedString(@"Oops", nil);
                        alertMsg = error.localizedDescription;
                    }
                } else {
                    [self signOut];
                }
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                               message:alertMsg
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                          style:UIAlertActionStyleDefault
                                                        handler:nil]];
                
                [self presentViewController:alert animated:YES completion:nil];

            }];
        } else {
            NSString *oops = NSLocalizedString(@"Oops",nil);
            NSString *textNoMatch = NSLocalizedString(@"The entered text doesn't match.", @"error message when user fails to input prompted text correctly");
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:oops
                                                                           message:textNoMatch
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)tappedDeleteAccount {    
    if ([[INatReachability sharedClient] isNetworkReachable]) {
                
        NSSet *scopes = [NSSet setWithArray:@[ @"login", @"write", @"account_delete" ]];
        
        NSURL *authorizationURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/oauth/authorize?client_id=%@&redirect_uri=urn%%3Aietf%%3Awg%%3Aoauth%%3A2.0%%3Aoob&response_type=code", [NSURL inat_baseURLForAuthentication], INatClientID ]];
        NSURL *tokenURL = [NSURL URLWithString:@"/oauth/token"
                                 relativeToURL:[NSURL inat_baseURLForAuthentication]];
        NSURL *redirectURL = [NSURL URLWithString:@"urn:ietf:wg:oauth:2.0:oob"];
        
        [[NXOAuth2AccountStore sharedStore] setClientID:INatClientID
                                                 secret:INatClientSecret
                                                  scope:scopes
                                       authorizationURL:authorizationURL
                                               tokenURL:tokenURL
                                            redirectURL:redirectURL
                                          keyChainGroup:nil
                                         forAccountType:kINatAuthService];
        
        // setup external auth as well
        tokenURL = [NSURL URLWithString:@"/oauth/assertion_token.json"
                          relativeToURL:[NSURL inat_baseURLForAuthentication]];
        redirectURL = [NSURL URLWithString:@"urn:ietf:wg:oauth:2.0:oob"];
        
        [[NXOAuth2AccountStore sharedStore] setClientID:INatClientID
                                                 secret:INatClientSecret
                                                  scope:scopes
                                       authorizationURL:authorizationURL
                                               tokenURL:tokenURL
                                            redirectURL:redirectURL
                                          keyChainGroup:nil
                                         forAccountType:kINatAuthServiceExtToken];

        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Onboarding" bundle:nil];
        OnboardingReauthenticateViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"onboarding-reauthenticate"];
        
        __weak typeof(self) weakSelf = self;
        vc.loginAction = ^{
            [weakSelf dismissViewControllerAnimated:YES completion:^{
                [weakSelf presentDeleteAccountConfirmation];
            }];
        };
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:nil];
    } else {
        [self networkUnreachableAlert];
    }
}

- (void)clickedSignOut {
    NSString *title = NSLocalizedString(@"Are you sure?",nil);
    NSString *msg = NSLocalizedString(@"This will destroy any changes/additions you've made from this app that haven't been synced with iNaturalist.org.",
                                      nil);
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:msg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",nil)
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sign out", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                [self signOut];
                                            }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)changeEmailTo:(NSString *)newEmail {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.tabBarController.view animated:YES];
    hud.removeFromSuperViewOnHide = YES;
    hud.dimBackground = YES;
    hud.labelText = NSLocalizedString(@"Updating...", nil);
    
    // the server validates the new username (since it might be a duplicate or something)
    // so don't change it locally
    
    __weak typeof(self) weakSelf = self;
    [[self peopleApi] setEmailAddress:newEmail forUserId:me.userId handler:^(NSArray *results, NSInteger count, NSError *error) {

        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hide:YES];
        });
        
        if (error) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Whoops", nil)
                                                                           message:error.localizedDescription
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                      style:UIAlertActionStyleDefault
                                                    handler:nil]];
            [weakSelf presentViewController:alert animated:YES completion:nil];
        } else {
            INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
            
            ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
            if (me) {
                RLMRealm *realm = [RLMRealm defaultRealm];
                [realm beginWriteTransaction];
                me.email = newEmail;
                [realm commitWriteTransaction];
                [weakSelf.tableView reloadData];
            }
        }
    }];
}

- (void)changeUsernameTo:(NSString *)newUsername {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.tabBarController.view animated:YES];
    hud.removeFromSuperViewOnHide = YES;
    hud.dimBackground = YES;
    hud.labelText = NSLocalizedString(@"Updating...", nil);
    
    // the server validates the new username (since it might be a duplicate or something)
    // so don't change it locally
    
    __weak typeof(self) weakSelf = self;
    [[self peopleApi] setUsername:newUsername forUserId:me.userId handler:^(NSArray *results, NSInteger count, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hide:YES];
        });
        
        if (error) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Whoops", nil)
                                                                           message:error.localizedDescription
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                      style:UIAlertActionStyleDefault
                                                    handler:nil]];
            [weakSelf presentViewController:alert animated:YES completion:nil];
        } else {
            RLMRealm *realm = [RLMRealm defaultRealm];
            [realm beginWriteTransaction];
            me.login = newUsername;
            [realm commitWriteTransaction];
            [[weakSelf tableView] reloadData];
        }
    }];
}

- (void)signOut {
    [[Analytics sharedClient] debugLog:@"User Logout"];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.tabBarController.view
                                              animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.dimBackground = YES;
    hud.labelText = NSLocalizedString(@"Signing Out", nil);
    hud.removeFromSuperViewOnHide = YES;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){        
        [self localSignOut];
                
        [hud hide:YES afterDelay:2.0f];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.navigationController popToRootViewControllerAnimated:YES];
        });
    });
}

- (void)localSignOut {
    // clear all preferences
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:NSBundle.mainBundle.bundleIdentifier];
    
    // also resets this stuff to defaults (all on except show scientific names first)
    [[NSUserDefaults standardUserDefaults] setBool:YES
                                            forKey:kINatAutocompleteNamesPrefKey];
    [[NSUserDefaults standardUserDefaults] setBool:YES
                                            forKey:kInatAutouploadPrefKey];
    [[NSUserDefaults standardUserDefaults] setBool:YES
                                            forKey:kINatSuggestionsPrefKey];
    [[NSUserDefaults standardUserDefaults] setBool:YES
                                            forKey:kINatShowCommonNamesPrefKey];
    [[NSUserDefaults standardUserDefaults] setBool:NO
                                            forKey:kINatShowScientificNamesFirstPrefKey];

    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // clear google signin
    if ([GIDSignIn.sharedInstance hasPreviousSignIn]) {
        [GIDSignIn.sharedInstance signOut];
    }
        
    // clear any oauth login info
    for (NXOAuth2Account *account in [[NXOAuth2AccountStore sharedStore] accounts]) {
        [[NXOAuth2AccountStore sharedStore] removeAccount:account];
    }
    
    // clear realm
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm deleteAllObjects];
    [realm commitWriteTransaction];
    // clear anything stashed in login
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.loginController logout];
    
    // clear the imagestore
    [[ImageStore sharedImageStore] clearEntireStore];
    
    // update UI
    [self.tableView reloadData];
}

- (void)launchTutorial {
#ifdef INatTutorialURL
    if ([[INatReachability sharedClient] isNetworkReachable]) {
        NSURL *url = [NSURL URLWithString:INatTutorialURL];
        if ([UIApplication.sharedApplication canOpenURL:url]) {
            [UIApplication.sharedApplication openURL:url
                                             options:@{}
                                   completionHandler:nil];
        }
    } else {
        [self networkUnreachableAlert];
    }
#else
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Cannot rate", @"Failure message")
                                                                   message:NSLocalizedString(@"No URL configured", nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
#endif
}

- (void)sendSupportEmail {
    // email params
    NSString *supportEmailAddress = @"help@inaturalist.org";
    
    NSString *supportUserInfo = @"user not logged in";
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([appDelegate.loginController isLoggedIn]) {
        ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
        supportUserInfo = [NSString stringWithFormat:@"user id: %ld, username: %@", (long)me.userId, me.login];
    }
    
    NSString *supportTitle = [NSString stringWithFormat:@"iNaturalist iPhone help - (version %@ %@)",
                              [[NSBundle mainBundle] versionString], supportUserInfo];
        
    // try built in mail client
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController* composeVC = [[MFMailComposeViewController alloc] init];
        composeVC.mailComposeDelegate = self;
        
        [composeVC setToRecipients:@[ supportEmailAddress ]];
        [composeVC setSubject:supportTitle];
        
        [self presentViewController:composeVC animated:YES completion:nil];
    } else {
        // try mailto:
        NSString *mailToUrlString = [NSString stringWithFormat:@"mailto:%@?subject=%@", supportEmailAddress, supportTitle];
        NSString *percentEncodedURLString = [[NSURL URLWithDataRepresentation:[mailToUrlString dataUsingEncoding:NSUTF8StringEncoding]
                                                                relativeToURL:nil] relativeString];
        
        NSURL *url = [NSURL URLWithString:percentEncodedURLString];
        if (url) {
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [UIApplication.sharedApplication openURL:url
                                                 options:@{}
                                       completionHandler:nil];
            } else {
                UIAlertController *alert = [[UIAlertController alloc] init];
                alert.title = NSLocalizedString(@"Cannot Send Email", @"Title of alert when the system is not configured for the user to send email");
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                          style:UIAlertActionStyleDefault
                                                        handler:nil]];
                
                [self presentViewController:alert animated:YES completion:nil];
            }
        }
    }
}



- (void)launchRateUs {
#ifdef INatAppStoreURL
    if ([[INatReachability sharedClient] isNetworkReachable]) {
        NSURL *url = [NSURL URLWithString:INatAppStoreURL];
        if ([UIApplication.sharedApplication canOpenURL:url]) {
            [UIApplication.sharedApplication openURL:url
                                             options:@{}
                                   completionHandler:nil];
        }
    } else {
        [self networkUnreachableAlert];
    }
#else
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Cannot rate", @"Failure message")
                                                                   message:NSLocalizedString(@"No URL configured", nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
#endif
}

- (void)launchDonate {
#ifdef INatDonateURL
    if ([[INatReachability sharedClient] isNetworkReachable]) {
        NSURL *url = [NSURL URLWithString:INatDonateURL];
        if ([UIApplication.sharedApplication canOpenURL:url]) {
            [UIApplication.sharedApplication openURL:url
                                             options:@{}
                                   completionHandler:nil];
        }
    } else {
        [self networkUnreachableAlert];
    }
#else
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Cannot donate", @"Failure message")
                                                                   message:NSLocalizedString(@"No URL configured", nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
#endif
}

- (void)launchStore {
#ifdef INatStoreURL
    if ([[INatReachability sharedClient] isNetworkReachable]) {
        NSURL *url = [NSURL URLWithString:INatStoreURL];
        if ([UIApplication.sharedApplication canOpenURL:url]) {
            [UIApplication.sharedApplication openURL:url
                                             options:@{}
                                   completionHandler:nil];
        }
    } else {
        [self networkUnreachableAlert];
    }
#else
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Cannot open store", @"Store launch failure message")
                                                                   message:NSLocalizedString(@"No URL configured", nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
#endif
}

- (void)launchCredits {
    AboutViewController *about = [AboutViewController acknowledgementsViewController];
    [self.navigationController pushViewController:about animated:YES];
    return;
}

- (void)switcherChanged:(UISwitch *)switcher {
    switch (switcher.tag) {
        case SettingsAppCellAutocompleteNames:
            [self settingChanged:kINatAutocompleteNamesPrefKey newValue:switcher.isOn];
            break;
        case SettingsAppCellAutomaticUpload:
            [self settingChanged:kInatAutouploadPrefKey newValue:switcher.isOn];
            break;
        case SettingsAppCellSuggestSpecies:
            [self settingChanged:kINatSuggestionsPrefKey newValue:switcher.isOn];
            break;
        case SettingsAppCellShowCommonNames:
            [self settingChanged:kINatShowCommonNamesPrefKey newValue:switcher.isOn];
            break;
        case SettingsAppCellShowScientficNamesFirst:
            [self settingChanged:kINatShowScientificNamesFirstPrefKey newValue:switcher.isOn];
            break;
        case SettingsAppCellPreferNoTracking:
            [self settingChanged:kINatPreferNoTrackPrefKey newValue:switcher.isOn];
            break;
        default:
            // do nothing
            break;
    }
}

- (void)settingChanged:(NSString *)key newValue:(BOOL)newValue {
    [[NSUserDefaults standardUserDefaults] setBool:newValue forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if ([key isEqualToString:kINatShowCommonNamesPrefKey]) {
        
        // make an api call to notify the server about this
        // not a critical setting, so fire and forget
        INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
        if (appDelegate.loggedIn) {
            ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
            [[self peopleApi] setPrefersShowCommonNames:newValue forUserId:me.userId handler:^(NSArray *results, NSInteger count, NSError *error) { }];
        }
        
    } else if ([key isEqualToString:kINatShowScientificNamesFirstPrefKey]) {
        
        // make an api call to notify the server about this
        // not a critical setting, so fire and forget
        INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
        if (appDelegate.loggedIn) {
            ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
            [[self peopleApi] setPrefersShowScientificNamesFirst:newValue forUserId:me.userId handler:^(NSArray *results, NSInteger count, NSError *error) { }];
        }
        
    } else if ([key isEqualToString:kINatPreferNoTrackPrefKey]) {
        if (newValue) {
            [Analytics enableCrashReporting];
        } else {
            [Analytics disableCrashReporting];
        }
        
        // make an API call to notify the server about this
        // note that we don't stash the setting on the me user
        // since it's not returned from the server every time.
        INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
        if (appDelegate.loggedIn) {
            ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
            __weak typeof(self) weakSelf = self;
            [[self peopleApi] setPrefersNoTracking:newValue forUserId:me.userId handler:^(NSArray *results, NSInteger count, NSError *error) {
                if (error) {
                    NSString *title = NSLocalizedString(@"Error changing setting.", @"failure title when changing a setting.");
                    NSString *msg = NSLocalizedString(@"Please try again later.", @"failure message when the user should just try again.");
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                                   message:msg
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                              style:UIAlertActionStyleDefault
                                                            handler:nil]];
                    [self presentViewController:alert animated:YES completion:nil];
                }
                [weakSelf.tableView reloadData];
            }];
        }

    } else if ([key isEqualToString:kInatAutouploadPrefKey]) {
        // kick off autouploads if necessary
        INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
        UploadManager *uploadManager = appDelegate.loginController.uploadManager;
        if (newValue) {
            // start autouploading right away
            if ([uploadManager shouldAutoupload]) {
                if (uploadManager.isNetworkAvailableForUpload) {
                    [uploadManager autouploadPendingContent];
                } else {
                    if (uploadManager.shouldNotifyAboutNetworkState) {
                        [JDStatusBarNotification showWithStatus:NSLocalizedString(@"Network Unavailable", nil)
                                                   dismissAfter:4];
                    }
                }
            }
        } else {
            // cancel autoupload if it's currently running
            if (uploadManager.state == UploadManagerStateUploading) {
                [uploadManager cancelSyncsAndUploads];
            }
        }
    }
}


#pragma mark - partner change stuff

- (NSDateFormatter *)networkPartnerChangeDateFormatter {
    static NSDateFormatter *_df = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _df = [[NSDateFormatter alloc] init];
        [_df setDateFormat:@"yyyy-MM-dd hh:mm:ss Z"];
    });
    return _df;
}

- (BOOL)canChangeNetworkPartner {
    NSString *lastChangeDateStr = [[NSUserDefaults standardUserDefaults] stringForKey:LastChangedPartnerDateKey];
    if (!lastChangeDateStr) {
        return YES;
    } else {
        NSDateFormatter *df = [self networkPartnerChangeDateFormatter];
        NSDate *lastChange = [df dateFromString:lastChangeDateStr];
        if (!lastChange) {
            return YES;
        } else {
            NSTimeInterval timeSinceChange = [[NSDate date] timeIntervalSinceDate:lastChange];
            if (timeSinceChange > ChangePartnerMinimumInterval) {
                return YES;
            } else {
                return NO;
            }
        }
    }
}

- (void)choseToChangeNetworkPartner {
    if ([self canChangeNetworkPartner]) {
        INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
        ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
        if (!me) { return; }

        NSMutableArray *partnerNames = [NSMutableArray array];
        for (Partner *p in self.partnerController.partners) {
            [partnerNames addObject:p.name];
        }

        Partner *currentPartner = [self.partnerController partnerForSiteId:me.siteId];
        
        __weak typeof(self) weakSelf = self;
        [[[ActionSheetStringPicker alloc] initWithTitle:NSLocalizedString(@"Choose iNat Network", "title of inat network picker")
                                                   rows:partnerNames
                                       initialSelection:[partnerNames indexOfObject:currentPartner.name]
                                              doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
                                                  __strong typeof(weakSelf) strongSelf = weakSelf;
                                                  // update base url
                                                  Partner *p = strongSelf.partnerController.partners[selectedIndex];
                                                  if (![p isEqual:currentPartner]) {
                                                      [weakSelf presentPartnerChangeAlertForPartner:p];
                                                  }
                                              }
                                            cancelBlock:nil
                                                 origin:self.view] showActionSheetPicker];
    } else {
        NSString *cantChangeMsg = NSLocalizedString(@"You can only change your network affiliation once per day.", @"failure message when the user tries to change their network affiliation too often");
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:cantChangeMsg
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                  style:UIAlertActionStyleDefault
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}


- (void)presentPartnerChangeAlertForPartner:(Partner *)partner {
    NSString *baseConfirmText = NSLocalizedString(@"%@ is a member of the iNaturalist Network in %@. Local institutions supporting %@ will have access to your email address and access to the true coordinates for observations that are publicly obscured or private. Would you like to change your affiliation?", @"confirmation alert text when changing a users network affiliation. %1%@ is network name, %2%@ is the country, %3%@ is the network name again");
    NSString *confirmMsg = [NSString stringWithFormat:baseConfirmText,
                            partner.name, partner.countryName, partner.name];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:confirmMsg
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSString *confirmAgreeText = NSLocalizedString(@"Yes, change my affiliation", @"change network partner button");
    NSString *confirmDisgreeText = NSLocalizedString(@"No, don’t change my affiliation", @"do not change network partner button");
    NSString *learnMoreText = NSLocalizedString(@"Learn more", @"learn more (about network partner changes) button text");

    
    __weak typeof(self)weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:confirmAgreeText
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                [weakSelf changePartner:partner];
                                            }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:confirmDisgreeText
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    
#ifdef INatPartnerLearnMoreURL
     [alert addAction:[UIAlertAction actionWithTitle:learnMoreText
                                       style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction * _Nonnull action) {
         NSURL *url = [NSURL URLWithString:INatPartnerLearnMoreURL];
         if ([UIApplication.sharedApplication canOpenURL:url]) {
             [UIApplication.sharedApplication openURL:url
                                              options:@{}
                                    completionHandler:nil];
         }
     }]];
#endif
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)changePartner:(Partner *)partner {
    NSDate *now = [NSDate date];
    NSString *nowString = [[self networkPartnerChangeDateFormatter] stringFromDate:now];
    [[NSUserDefaults standardUserDefaults] setObject:nowString
                                              forKey:LastChangedPartnerDateKey];

    __weak typeof(self)weakSelf = self;
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate.loginController loggedInUserSelectedPartner:partner
                                                  completion:^{
                                                      [weakSelf.tableView reloadData];
                                                  }];

}

#pragma mark - MFMAilCompose delegate

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
   [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UITableView

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == SettingsSectionAccount) {
        return NSLocalizedString(@"Your Account", @"Title for account section of settings.");
    } else if (section == SettingsSectionApp) {
        return NSLocalizedString(@"App Settings", @"Title for app section of settings.");
    } else if (section == SettingsSectionHelp) {
        return NSLocalizedString(@"Help", @"Title for help section of settings.");
    } else if (section == SettingsSectionVersion) {
        return NSLocalizedString(@"Version", @"Title for version section of settings.");
    } else if (section == SettingsSectionDanger) {
        return NSLocalizedString(@"Danger Zone", @"Title for danger zone (account deletion) section of settings.");
    } else {
        return nil;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.loggedIn) {
        return SettingsLoggedInSectionCount;
    } else {
        return SettingsLoggedOutSectionCount;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == SettingsSectionAccount) {
        INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
        if (appDelegate.loginController.isLoggedIn) {
            return SettingsAccountRowCountLoggedIn;
        } else {
            return SettingsAccountRowCountLoggedOut;
        }
    } else if (section == SettingsSectionApp) {
        return SettingsAppRowCount;
    } else if (section == SettingsSectionHelp) {
        return SettingsHelpRowCount;
    } else if (section == SettingsSectionVersion) {
        return SettingsVersionRowCount;
    } else if (section == SettingsSectionDanger) {
        return SettingsDangerRowCount;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SettingsSectionAccount) {
        INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
        if (appDelegate.loginController.isLoggedIn) {
            if (indexPath.item == SettingsAccountCellUsername) {
                return [self tableView:tableView accountUsernameCellForIndexPath:indexPath];
            } else if (indexPath.item == SettingsAccountCellEmail) {
                return [self tableView:tableView accountEmailCellForIndexPath:indexPath];
            } else {
                return [self tableView:tableView accountActionCellForIndexPath:indexPath];
            }
        } else {
            return [self tableView:tableView accountActionCellForIndexPath:indexPath];
        }
    } else if (indexPath.section == SettingsSectionApp) {
        if (indexPath.item == SettingsAppCellChangeUsername) {
            return [self tableView:tableView appChangeUsernameCellForIndexPath:indexPath];
        } else if (indexPath.item == SettingsAppCellChangeEmail) {
            return [self tableView:tableView appChangeEmailCellForIndexPath:indexPath];
        } else if (indexPath.item == SettingsAppCellAutocompleteNames) {
            return [self tableView:tableView appAutocompleteNamesCellForIndexPath:indexPath];
        } else if (indexPath.item == SettingsAppCellAutomaticUpload) {
            return [self tableView:tableView appAutoUploadCellForIndexPath:indexPath];
        } else if (indexPath.item == SettingsAppCellSuggestSpecies) {
            return [self tableView:tableView appSuggestSpeciesCellForIndexPath:indexPath];
        } else if (indexPath.item == SettingsAppCellShowCommonNames) {
            return [self tableView:tableView appShowCommonNamesCellForIndexPath:indexPath];
        } else if (indexPath.item == SettingsAppCellShowScientficNamesFirst) {
            return [self tableView:tableView appShowScientificNamesFirstCellForIndexPath:indexPath];
        } else if (indexPath.item == SettingsAppCellPreferNoTracking) {
            return [self tableView:tableView appPrefersNoTrackingCellForIndexPath:indexPath];
        } else {
            return [self tableView:tableView appInaturalistNetworkCellForIndexPath:indexPath];
        }
    } else if (indexPath.section == SettingsSectionHelp) {
        if (indexPath.item == SettingsHelpCellTutorial) {
            return [self tableView:tableView tutorialCellForIndexPath:indexPath];
        } else if (indexPath.item == SettingsHelpCellContact) {
            return [self tableView:tableView contactUsCellForIndexPath:indexPath];
        } else if (indexPath.item == SettingsHelpCellReview) {
            return [self tableView:tableView rateUsCellForIndexPath:indexPath];
        } else if (indexPath.item == SettingsHelpCellStore) {
            return [self tableView:tableView storeCellForIndexPath:indexPath];
        } else {
            return [self tableView:tableView donateCellForIndexPath:indexPath];
        }
    } else if (indexPath.section == SettingsSectionVersion) {
        return [self tableView:tableView versionCellForIndexPath:indexPath];
    } else {
        return [self tableView:tableView deleteAccountCellForIndexPath:indexPath];
    }
}

#pragma mark - UITableViewDataSource
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (indexPath.section == SettingsSectionApp) {
        if (indexPath.item == SettingsAppCellChangeUsername) {
            if (![appDelegate.loginController isLoggedIn]) {
                [self presentSignup];
            } else {
                [self tappedUsername];
            }
        } else if (indexPath.item == SettingsAppCellChangeEmail) {
            if (![appDelegate.loginController isLoggedIn]) {
                [self presentSignup];
            } else {
                [self tappedEmail];
            }
        } else if (indexPath.item == SettingsAppCellNetwork) {
			if (![appDelegate.loginController isLoggedIn]) {
				[self presentSignup];
            } else {
                [self choseToChangeNetworkPartner];
            }
            
            return;
        } else {
            // do nothing
            return;
        }
    } else if (indexPath.section == SettingsSectionHelp) {
        if (indexPath.item == SettingsHelpCellTutorial) {
            [self launchTutorial];
        } else if (indexPath.item == SettingsHelpCellContact) {
            [self sendSupportEmail];
        } else if (indexPath.item == SettingsHelpCellReview) {
            [self launchRateUs];
        } else if (indexPath.item == SettingsHelpCellStore) {
            [self launchStore];
        } else if (indexPath.item == SettingsHelpCellDonate) {
            [self launchDonate];
        }
    } else if (indexPath.section == SettingsSectionAccount) {
        INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
        if (indexPath.item == SettingsAccountCellUsername) {
            if ([appDelegate.loginController isLoggedIn]) {
                [self tappedUsername];
            } else {
                if ([[INatReachability sharedClient] isNetworkReachable]) {
                    [self presentSignup];
                } else {
                    [self networkUnreachableAlert];
                }
            }
        } else if (indexPath.item == SettingsAccountCellEmail) {
            if ([appDelegate.loginController isLoggedIn]) {
                [self tappedEmail];
            } else {
                if ([[INatReachability sharedClient] isNetworkReachable]) {
                    [self presentSignup];
                } else {
                    [self networkUnreachableAlert];
                }
            }
        } else if (indexPath.item == SettingsAccountCellAction) {
            if ([appDelegate.loginController isLoggedIn]) {
                [self clickedSignOut];
            } else {
                if ([[INatReachability sharedClient] isNetworkReachable]) {
                    [self presentSignup];
                } else {
                    [self networkUnreachableAlert];
                }
            }
        }
    } else if (indexPath.section == SettingsSectionDanger) {
        [self tappedDeleteAccount];
    }
}

#pragma mark - TableView Helpers

- (UITableViewCell *)tableView:(UITableView *)tableView accountUsernameCellForIndexPath:(NSIndexPath *)indexPath {
    SettingsDetailTextCell *cell = [tableView dequeueReusableCellWithIdentifier:@"detailText"
                                                                   forIndexPath:indexPath];
    cell.leadingTextLabel.text = NSLocalizedString(@"Username", @"label for username field in settings");
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    cell.trailingTextLabel.text = appDelegate.loginController.meUserLocal.login;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView accountEmailCellForIndexPath:(NSIndexPath *)indexPath {
    SettingsDetailTextCell *cell = [tableView dequeueReusableCellWithIdentifier:@"detailText"
                                                                   forIndexPath:indexPath];
    cell.leadingTextLabel.text = NSLocalizedString(@"Email", @"label for email field in settings");
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    cell.trailingTextLabel.text = appDelegate.loginController.meUserLocal.email;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView accountActionCellForIndexPath:(NSIndexPath *)indexPath {
    SettingsActionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"action"
                                                               forIndexPath:indexPath];
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.loggedIn) {
        cell.actionLabel.text = NSLocalizedString(@"Sign out",nil);
    } else {
        cell.actionLabel.text = NSLocalizedString(@"Log In / Sign Up",nil);
    }
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView appChangeUsernameCellForIndexPath:(NSIndexPath *)indexPath {
    SettingsDetailTextCell *cell = [tableView dequeueReusableCellWithIdentifier:@"detailText"
                                                                   forIndexPath:indexPath];
    cell.leadingTextLabel.text = NSLocalizedString(@"Change username", @"label for change username action in settings");
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView appChangeEmailCellForIndexPath:(NSIndexPath *)indexPath {
    SettingsDetailTextCell *cell = [tableView dequeueReusableCellWithIdentifier:@"detailText"
                                                                   forIndexPath:indexPath];
    cell.leadingTextLabel.text = NSLocalizedString(@"Change email", @"label for change email address action in settings");
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView appAutocompleteNamesCellForIndexPath:(NSIndexPath *)indexPath {
    SettingsSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"switch"
                                                               forIndexPath:indexPath];
    cell.switchLabel.text = NSLocalizedString(@"Autocomplete names", @"label for autocomplete names switch in settings");
    cell.switcher.on = [[NSUserDefaults standardUserDefaults] boolForKey:kINatAutocompleteNamesPrefKey];

    cell.switcher.tag = SettingsAppCellAutocompleteNames;
    [cell.switcher addTarget:self
                      action:@selector(switcherChanged:)
            forControlEvents:UIControlEventValueChanged];

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView appAutoUploadCellForIndexPath:(NSIndexPath *)indexPath {
    SettingsSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"switch"
                                                               forIndexPath:indexPath];
    cell.switchLabel.text = NSLocalizedString(@"Automatic upload", @"label for auto upload switch in settings");
    cell.switcher.on = [[NSUserDefaults standardUserDefaults] boolForKey:kInatAutouploadPrefKey];

    cell.switcher.tag = SettingsAppCellAutomaticUpload;
    [cell.switcher addTarget:self
                      action:@selector(switcherChanged:)
            forControlEvents:UIControlEventValueChanged];

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView appSuggestSpeciesCellForIndexPath:(NSIndexPath *)indexPath {
    SettingsSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"switch"
                                                               forIndexPath:indexPath];
    cell.switchLabel.text = NSLocalizedString(@"Suggest species", @"label for suggest species switch in settings");
    cell.switcher.on = [[NSUserDefaults standardUserDefaults] boolForKey:kINatSuggestionsPrefKey];

    cell.switcher.tag = SettingsAppCellSuggestSpecies;
    [cell.switcher addTarget:self
                      action:@selector(switcherChanged:)
            forControlEvents:UIControlEventValueChanged];

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView appShowCommonNamesCellForIndexPath:(NSIndexPath *)indexPath {
    SettingsSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"switch"
                                                               forIndexPath:indexPath];
    cell.switchLabel.text = NSLocalizedString(@"Show common names", @"label for show common names switch in settings");
    cell.switcher.on = [[NSUserDefaults standardUserDefaults] boolForKey:kINatShowCommonNamesPrefKey];

    cell.switcher.tag = SettingsAppCellShowCommonNames;
    [cell.switcher addTarget:self
                      action:@selector(switcherChanged:)
            forControlEvents:UIControlEventValueChanged];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView appShowScientificNamesFirstCellForIndexPath:(NSIndexPath *)indexPath {
    SettingsSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"switch"
                                                               forIndexPath:indexPath];
    cell.switchLabel.text = NSLocalizedString(@"Show scientific names first", @"label for scientific names shown first switch in settings");
    cell.switcher.on = [[NSUserDefaults standardUserDefaults] boolForKey:kINatShowScientificNamesFirstPrefKey];

    cell.switcher.tag = SettingsAppCellShowScientficNamesFirst;
    [cell.switcher addTarget:self
                      action:@selector(switcherChanged:)
            forControlEvents:UIControlEventValueChanged];

    return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView appPrefersNoTrackingCellForIndexPath:(NSIndexPath *)indexPath {
    
    SettingsSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"switch"
                                                               forIndexPath:indexPath];
    cell.switchLabel.text = NSLocalizedString(@"Prefer No Tracking", @"label for prefer no tracking switch in settings");
    
    cell.switcher.on = [[NSUserDefaults standardUserDefaults] boolForKey:kINatPreferNoTrackPrefKey];
    
    cell.switcher.tag = SettingsAppCellPreferNoTracking;
    [cell.switcher addTarget:self
                      action:@selector(switcherChanged:)
            forControlEvents:UIControlEventValueChanged];

    return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView appInaturalistNetworkCellForIndexPath:(NSIndexPath *)indexPath {
    SettingsDetailTextCell *cell = [tableView dequeueReusableCellWithIdentifier:@"detailText"
                                                                   forIndexPath:indexPath];
    cell.leadingTextLabel.text = NSLocalizedString(@"iNaturalist Network", @"label for inaturalist network action in settings");
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
    if (me) {
        Partner *p = [self.partnerController partnerForSiteId:me.siteId];
        cell.trailingTextLabel.text = p.shortName;
    } else {
        cell.trailingTextLabel.text = @"iNaturalist";
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView tutorialCellForIndexPath:(NSIndexPath *)indexPath {
    SettingsDetailTextCell *cell = [tableView dequeueReusableCellWithIdentifier:@"detailText"
                                                                   forIndexPath:indexPath];
    cell.leadingTextLabel.text = NSLocalizedString(@"Video Tutorial", @"label for start video tutorial action in settings.");
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView contactUsCellForIndexPath:(NSIndexPath *)indexPath {
    SettingsDetailTextCell *cell = [tableView dequeueReusableCellWithIdentifier:@"detailText"
                                                                   forIndexPath:indexPath];
    cell.leadingTextLabel.text = NSLocalizedString(@"Contact support", @"label for contact support action in settings.");
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView rateUsCellForIndexPath:(NSIndexPath *)indexPath {
    SettingsDetailTextCell *cell = [tableView dequeueReusableCellWithIdentifier:@"detailText"
                                                                   forIndexPath:indexPath];
    cell.leadingTextLabel.text = NSLocalizedString(@"Love iNat? Rate us", @"label for app store rating action in settings.");
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView storeCellForIndexPath:(NSIndexPath *)indexPath {
    SettingsDetailTextCell *cell = [tableView dequeueReusableCellWithIdentifier:@"detailText"
                                                                   forIndexPath:indexPath];
    cell.leadingTextLabel.text = NSLocalizedString(@"Shop the iNat Store", @"label for iNaturalist store (tshirts/etc) action in settings.");
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView donateCellForIndexPath:(NSIndexPath *)indexPath {
    SettingsDetailTextCell *cell = [tableView dequeueReusableCellWithIdentifier:@"detailText"
                                                                   forIndexPath:indexPath];
    cell.leadingTextLabel.text = NSLocalizedString(@"Donate to iNaturalist", @"label for iNaturalist donate call to action.");
    return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView versionCellForIndexPath:(NSIndexPath *)indexPath {
    SettingsVersionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"version"
                                                                forIndexPath:indexPath];
    cell.versionLabel.text = [NSString stringWithFormat:@"%@ - %@",
                              [[NSBundle mainBundle] versionString],
                              [[ImageStore sharedImageStore] usageStatsString]];
    cell.versionLabel.textAlignment = NSTextAlignmentNatural;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView deleteAccountCellForIndexPath:(NSIndexPath *)indexPath {
    SettingsActionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"action"
                                                               forIndexPath:indexPath];
    
    cell.actionLabel.text = NSLocalizedString(@"Delete Account", @"button title to delete account");
    cell.actionLabel.tintColor = UIColor.systemRedColor;

    return cell;
}


@end

