//
//  SettingsViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/27/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <VTAcknowledgementsViewController/VTAcknowledgementsViewController.h>
#import <JDFTooltips/JDFTooltips.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <MHVideoPhotoGallery/MHGalleryController.h>
#import <MHVideoPhotoGallery/MHGallery.h>
#import <MHVideoPhotoGallery/MHTransitionDismissMHGallery.h>
#import <GoogleSignIn/GoogleSignIn.h>
#import <ActionSheetPicker-3.0/ActionSheetStringPicker.h>
#import <JDStatusBarNotification/JDStatusBarNotification.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <Realm/Realm.h>
#import <RestKit/RestKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <SafariServices/SafariServices.h>

#import "SettingsViewController.h"
#import "Observation.h"
#import "ObservationPhoto.h"
#import "ProjectUser.h"
#import "ProjectObservation.h"
#import "Comment.h"
#import "Identification.h"
#import "DeletedRecord.h"
#import "INatUITabBarController.h"
#import "NXOAuth2.h"
#import "Analytics.h"
#import "INaturalistAppDelegate.h"
#import "PartnerController.h"
#import "Partner.h"
#import "LoginController.h"
#import "UploadManager.h"
#import "UIColor+INaturalist.h"
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

typedef NS_ENUM(NSInteger, SettingsSection) {
    SettingsSectionAccount = 0,
    SettingsSectionApp,
    SettingsSectionHelp,
    SettingsSectionVersion
};
static const int SettingsSectionCount = 4;

typedef NS_ENUM(NSInteger, SettingsHelpCell) {
    SettingsHelpCellTutorial = 0,
    SettingsHelpCellContact,
    SettingsHelpCellReview,
    SettingsHelpCellDonate
};
static const int SettingsHelpRowCount = 4;

typedef NS_ENUM(NSInteger, SettingsAppCell) {
    SettingsAppCellChangeUsername = 0,
    SettingsAppCellChangeEmail,
    SettingsAppCellAutocompleteNames,
    SettingsAppCellAutomaticUpload,
    SettingsAppCellSuggestSpecies,
    SettingsAppCellNetwork
};
static const int SettingsAppRowCount = 6;

typedef NS_ENUM(NSInteger, SettingsAccountCell) {
    SettingsAccountCellUsername,
    SettingsAccountCellEmail,
    SettingsAccountCellAction
};
static const int SettingsAccountRowCountLoggedIn = 3;
static const int SettingsAccountRowCountLoggedOut = 1;
static const int SettingsVersionRowCount = 1;

static const NSString *LastChangedPartnerDateKey = @"org.inaturalist.lastChangedPartnerDateKey";
static const int ChangePartnerMinimumInterval = 86400;

@interface SettingsViewController () {
    UITapGestureRecognizer *tapAway;
    JDFTooltipView *tooltip;
}
@property (nonatomic, strong) NSString *versionText;
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

#pragma mark - UI helpers

- (void)presentSignup {
    [[Analytics sharedClient] event:kAnalyticsEventNavigateOnboardingScreenLogin
                     withProperties:@{ @"via": @"settings" }];
    
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
    
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    self.versionText = [NSString stringWithFormat:NSLocalizedString(@"%@, build %@",nil),
                        [info objectForKey:@"CFBundleShortVersionString"] ?: @"unknown version",
                        [info objectForKey:@"CFBundleVersion"] ?: @"unknown version"];
    
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
    if (login.isLoggedIn) {
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
            [[Analytics sharedClient] event:kAnalyticsEventProfileLoginChanged];
            
            RLMRealm *realm = [RLMRealm defaultRealm];
            [realm beginWriteTransaction];
            me.login = newUsername;
            [realm commitWriteTransaction];
            [[weakSelf tableView] reloadData];
        }
    }];
}

- (void)signOut
{
    [[Analytics sharedClient] event:kAnalyticsEventLogout];
    [[Analytics sharedClient] debugLog:@"User Logout"];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.tabBarController.view
                                              animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.dimBackground = YES;
    hud.labelText = NSLocalizedString(@"Signing Out", nil);
    hud.removeFromSuperViewOnHide = YES;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [[[RKClient sharedClient] requestQueue] cancelAllRequests];
        
        [self localSignOut];
        
        INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate rebuildCoreData];
        
        [hud hide:YES afterDelay:2.0f];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.navigationController popToRootViewControllerAnimated:YES];
        });
    });
}

- (void)localSignOut
{
    // clear preference cached signin info & preferences
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:INatUsernamePrefKey];
    [defaults removeObjectForKey:kINatUserIdPrefKey];
    [defaults removeObjectForKey:INatPasswordPrefKey];
    [defaults removeObjectForKey:INatTokenPrefKey];
    [defaults removeObjectForKey:kInatCustomBaseURLStringKey];
    [defaults synchronize];
    
    // clear google signin
    if ([[GIDSignIn sharedInstance] hasAuthInKeychain]) {
        [[GIDSignIn sharedInstance] signOut];
    }
    
    // clear facebook login
    if ([FBSDKAccessToken currentAccessToken]) {
        FBSDKLoginManager *fb = [[FBSDKLoginManager alloc] init];
        [fb logOut];
    }
    
    // clear any oauth login info
    for (NXOAuth2Account *account in [[NXOAuth2AccountStore sharedStore] accounts]) {
        [[NXOAuth2AccountStore sharedStore] removeAccount:account];
    }
    
    // clear cached RKClient authentication details
    [RKClient.sharedClient setUsername:nil];
    [RKClient.sharedClient setPassword:nil];
    [RKClient.sharedClient setValue:nil forHTTPHeaderField:@"Authorization"];
    
    // since we've removed any custom base URL, reconfigure RestKit again
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate reconfigureForNewBaseUrl];
    
    // clear realm
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm deleteAllObjects];
    [realm commitWriteTransaction];
    
    // clear anything stashed in login
    [appDelegate.loginController logout];
    
    // clear the imagestore
    [[ImageStore sharedImageStore] clearEntireStore];
    
    // update UI
    [self.tableView reloadData];
}

- (void)launchTutorial {
#ifdef INatTutorialURL
    if ([[INatReachability sharedClient] isNetworkReachable]) {
        [[Analytics sharedClient] event:kAnalyticsEventTutorial];
        NSURL *tutorialUrl = [NSURL URLWithString:INatTutorialURL];
        
        SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:tutorialUrl];
        [self.navigationController presentViewController:safari animated:YES completion:nil];
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

- (void)sendSupportEmail
{
    NSString *email = [NSString stringWithFormat:@"mailto://help@inaturalist.org?cc=&subject=iNaturalist iPhone help - version: %@",
                       self.versionText];
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if ([appDelegate.loginController isLoggedIn]) {
        ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
        email = [email stringByAppendingString:[NSString stringWithFormat:@" user id: %ld,", (long)me.userId]];
        email = [email stringByAppendingString:[NSString stringWithFormat:@" username: %@", me.login]];
    } else {
        email = [email stringByAppendingString:@" user not logged in"];
    }
    
    email = [email stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
}

- (void)launchRateUs {
#ifdef INatAppStoreURL
    if ([[INatReachability sharedClient] isNetworkReachable]) {
        [[Analytics sharedClient] event:kAnalyticsEventSettingsRateUs];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:INatAppStoreURL]];
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
        [[Analytics sharedClient] event:kAnalyticsEventSettingsDonate];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:INatDonateURL]];
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

- (void)launchCredits {
    AboutViewController *about = [AboutViewController acknowledgementsViewController];
    [self.navigationController pushViewController:about animated:YES];
    return;
}

- (void)settingChanged:(NSString *)key newValue:(BOOL)newValue {
    NSString *analyticsEvent = newValue ? kAnalyticsEventSettingEnabled : kAnalyticsEventSettingDisabled;
    [[Analytics sharedClient] event:analyticsEvent
                     withProperties:@{ @"setting": key }];
    [[NSUserDefaults standardUserDefaults] setBool:newValue forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // kick off autouploads if necessary
    
    if ([key isEqualToString:kInatAutouploadPrefKey]) {
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
        [[Analytics sharedClient] event:kAnalyticsEventSettingsNetworkChangeBegan];

        INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
        ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
        if (!me) { return; }
        
        NSArray *partnerNames = [self.partnerController.partners bk_map:^id(Partner *p) {
            return p.name;
        }];
        
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
    
     [alert addAction:[UIAlertAction actionWithTitle:learnMoreText
                                       style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction * _Nonnull action) {
                                                 UIApplication *app = [UIApplication sharedApplication];
                                                 [app openURL:[NSURL URLWithString:INatPartnerLearnMoreURL]];
                                             }]];
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
                                                      [[Analytics sharedClient] event:kAnalyticsEventSettingsNetworkChangeCompleted];
                                                      [weakSelf.tableView reloadData];
                                                  }];

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
    } else {
        return nil;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return SettingsSectionCount;
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
        } else {
            return [self tableView:tableView donateCellForIndexPath:indexPath];
        }
    } else {
        return [self tableView:tableView versionCellForIndexPath:indexPath];
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
            // show popover
            NSString *tooltipText;
            if (indexPath.item == SettingsAppCellAutocompleteNames) {
                // autocorrect
                tooltipText = NSLocalizedString(@"Enable to allow iOS to auto-correct and spell-check Species names.", @"tooltip text for autocorrect settings option.");
            } else if (indexPath.item == SettingsAppCellAutomaticUpload) {
                // automatically upload
                tooltipText = NSLocalizedString(@"Automatically upload new or edited content to iNaturalist.org",
                                                @"tooltip text for automatically upload option.");
            } else if (indexPath.item == SettingsAppCellSuggestSpecies) {
                // suggestions
                tooltipText = NSLocalizedString(@"Show species suggestions for observations or identifications", nil);
            }
            
            tooltip = [[JDFTooltipView alloc] initWithTargetView:[[tableView cellForRowAtIndexPath:indexPath] viewWithTag:100+indexPath.item]
                                                        hostView:tableView
                                                     tooltipText:tooltipText
                                                  arrowDirection:JDFTooltipViewArrowDirectionDown
                                                           width:200.0f
                                             showCompletionBlock:^{
                                                 if (!tapAway) {
                                                     tapAway = [[UITapGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
                                                         [tooltip hideAnimated:YES];
                                                     }];
                                                     [self.view addGestureRecognizer:tapAway];
                                                 }
                                                 tapAway.enabled = YES;
                                             } hideCompletionBlock:^{
                                                 tapAway.enabled = NO;
                                             }];
            [tooltip show];
            
            
            return;
        }
    } else if (indexPath.section == SettingsSectionHelp) {
        if (indexPath.item == SettingsHelpCellTutorial) {
            [self launchTutorial];
        } else if (indexPath.item == SettingsHelpCellContact) {
            [self sendSupportEmail];
        } else if (indexPath.item == SettingsHelpCellReview) {
            [self launchRateUs];
        } else {
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
    __weak typeof(self)weakSelf = self;
    [cell.switcher bk_addEventHandler:^(UISwitch *sender) {
        [weakSelf settingChanged:kINatAutocompleteNamesPrefKey newValue:sender.isOn];
    } forControlEvents:UIControlEventValueChanged];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView appAutoUploadCellForIndexPath:(NSIndexPath *)indexPath {
    SettingsSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"switch"
                                                               forIndexPath:indexPath];
    cell.switchLabel.text = NSLocalizedString(@"Automatic upload", @"label for auto upload switch in settings");
    cell.switcher.on = [[NSUserDefaults standardUserDefaults] boolForKey:kInatAutouploadPrefKey];
    __weak typeof(self)weakSelf = self;
    [cell.switcher bk_addEventHandler:^(UISwitch *sender) {
        [weakSelf settingChanged:kInatAutouploadPrefKey newValue:sender.isOn];
    } forControlEvents:UIControlEventValueChanged];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView appSuggestSpeciesCellForIndexPath:(NSIndexPath *)indexPath {
    SettingsSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"switch"
                                                               forIndexPath:indexPath];
    cell.switchLabel.text = NSLocalizedString(@"Suggest species", @"label for suggest species switch in settings");
    cell.switcher.on = [[NSUserDefaults standardUserDefaults] boolForKey:kINatSuggestionsPrefKey];
    __weak typeof(self)weakSelf = self;
    [cell.switcher bk_addEventHandler:^(UISwitch *sender) {
        [weakSelf settingChanged:kINatSuggestionsPrefKey newValue:sender.isOn];
    } forControlEvents:UIControlEventValueChanged];
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

- (UITableViewCell *)tableView:(UITableView *)tableView donateCellForIndexPath:(NSIndexPath *)indexPath {
    SettingsDetailTextCell *cell = [tableView dequeueReusableCellWithIdentifier:@"detailText"
                                                                   forIndexPath:indexPath];
    cell.leadingTextLabel.text = NSLocalizedString(@"Donate to iNaturalist", @"label for donate action in settings.");
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView versionCellForIndexPath:(NSIndexPath *)indexPath {
    SettingsVersionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"version"
                                                                forIndexPath:indexPath];
    cell.versionLabel.text = [NSString stringWithFormat:@"%@ - %@",
                              self.versionText,
                              [[ImageStore sharedImageStore] usageStatsString]];
    cell.versionLabel.textAlignment = NSTextAlignmentNatural;
    return cell;
}

@end

