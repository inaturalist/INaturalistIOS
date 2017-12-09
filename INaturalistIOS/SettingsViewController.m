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
#import <GooglePlus/GPPSignIn.h>
#import <GoogleOpenSource/GTMOAuth2Authentication.h>
#import <ActionSheetPicker-3.0/ActionSheetStringPicker.h>
#import <JDStatusBarNotification/JDStatusBarNotification.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <Realm/Realm.h>
#import <RestKit/RestKit.h>

#import "SettingsViewController.h"
#import "Observation.h"
#import "ObservationPhoto.h"
#import "ProjectUser.h"
#import "ProjectObservation.h"
#import "Comment.h"
#import "Identification.h"
#import "User.h"
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

static const int CreditsSection = 3;

static const int NetworkDetailLabelTag = 14;
static const int NetworkTextLabelTag = 15;

static const int AutocompleteNamesLabelTag = 51;
static const int AutouploadLabelTag = 52;
static const int SuggestionsLabelTag = 53;
static const int AutocompleteNamesSwitchTag = 101;
static const int AutouploadSwitchTag = 102;
static const int SuggestionsSwitchTag = 103;

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

- (void)initUI
{
    self.navigationController.navigationBar.translucent = NO;
    
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    self.versionText = [NSString stringWithFormat:NSLocalizedString(@"%@, build %@",nil),
                        [info objectForKey:@"CFBundleShortVersionString"],
                        [info objectForKey:@"CFBundleVersion"]];
    
    [self.tableView reloadData];
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
            User *me = [appDelegate.loginController fetchMe];
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
                                                    User *me = [appDelegate.loginController fetchMe];
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
    NSString *msg = NSLocalizedString(@"This will delete all your observations on this device.  It will not affect any observations you've uploaded to iNaturalist.",
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

- (void)changeUsernameTo:(NSString *)newUsername {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    User *me = [appDelegate.loginController fetchMe];
    
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.tabBarController.view animated:YES];
    hud.removeFromSuperViewOnHide = YES;
    hud.dimBackground = YES;
    hud.labelText = NSLocalizedString(@"Updating...", nil);

    // the server validates the new username (since it might be a duplicate or something)
    // so don't change it locally

    __weak typeof(self) weakSelf = self;
    [[self peopleApi] setUsername:newUsername forUser:me handler:^(NSArray *results, NSInteger count, NSError *error) {
        
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
            
            RKObjectManager *manager = [RKObjectManager sharedManager];
            
            [manager loadObjectsAtResourcePath:[NSString stringWithFormat:@"/users/%ld.json", (long)me.recordID.integerValue ]
                                                               usingBlock:^(RKObjectLoader *loader) {
                                                                   loader.objectMapping = [User mapping];
                                                                   loader.onDidLoadObject = ^(id object) {
                                                                       NSError *error = nil;
                                                                       [[User managedObjectContext] save:&error];
                                                                       [[weakSelf tableView] reloadData];
                                                                   };
                                                               }];
        }
    }];
}

- (void)signOut
{
    [[Analytics sharedClient] event:kAnalyticsEventLogout];

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
    });
}

- (void)localSignOut
{
    // clear g+
    if ([[GPPSignIn sharedInstance] hasAuthInKeychain]) [[GPPSignIn sharedInstance] disconnect];

    // clear preference cached signin info & preferences
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:INatUsernamePrefKey];
    [defaults removeObjectForKey:kINatUserIdPrefKey];
    [defaults removeObjectForKey:INatPasswordPrefKey];
    [defaults removeObjectForKey:INatTokenPrefKey];
    [defaults removeObjectForKey:kInatCustomBaseURLStringKey];
    [defaults synchronize];
    
    // clear cached RKClient authentication details
    [RKClient.sharedClient setUsername:nil];
    [RKClient.sharedClient setPassword:nil];
    [RKClient.sharedClient setValue:nil forHTTPHeaderField:@"Authorization"];
    
    // since we've removed any custom base URL, reconfigure RestKit again
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate reconfigureForNewBaseUrl];
    
    // remove OAuth account stuff
    NXOAuth2AccountStore *sharedStore = [NXOAuth2AccountStore sharedStore];
    for (NXOAuth2Account *account in sharedStore.accounts) {
        [sharedStore removeAccount:account];
    }
    
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
    [self initUI];
}

- (void)launchTutorial
{
    NSArray *tutorialImages = @[
                                [UIImage imageNamed:@"tutorial1"],
                                [UIImage imageNamed:@"tutorial2"],
                                [UIImage imageNamed:@"tutorial3"],
                                [UIImage imageNamed:@"tutorial4"],
                                [UIImage imageNamed:@"tutorial5"],
                                [UIImage imageNamed:@"tutorial6"],
                                [UIImage imageNamed:@"tutorial7"],
                                ];
    
    NSArray *galleryData = [tutorialImages bk_map:^id(UIImage *image) {
        return [MHGalleryItem itemWithImage:image];
    }];
    
    MHUICustomization *customization = [[MHUICustomization alloc] init];
    customization.showOverView = NO;
    customization.showMHShareViewInsteadOfActivityViewController = NO;
    customization.hideShare = YES;
    customization.useCustomBackButtonImageOnImageViewer = NO;
    
    MHGalleryController *gallery = [MHGalleryController galleryWithPresentationStyle:MHGalleryViewModeImageViewerNavigationBarShown];
    gallery.galleryItems = galleryData;
    gallery.presentationIndex = 0;
    gallery.UICustomization = customization;
    
    __weak MHGalleryController *blockGallery = gallery;
    
    gallery.finishedCallback = ^(NSInteger currentIndex, UIImage *image, MHTransitionDismissMHGallery *interactiveTransition, MHGalleryViewMode viewMode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [blockGallery dismissViewControllerAnimated:YES completion:nil];
        });
    };
    [self presentMHGalleryController:gallery animated:YES completion:nil];
}

- (void)sendSupportEmail
{
    NSString *email = [NSString stringWithFormat:@"mailto://help@inaturalist.org?cc=&subject=iNaturalist iPhone help: version %@",
                       self.versionText];
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if ([appDelegate.loginController isLoggedIn]) {
        User *me = [appDelegate.loginController fetchMe];
        email = [email stringByAppendingString:[NSString stringWithFormat:@" user id %ld", (long)me.recordID.integerValue]];
    } else {
        email = [email stringByAppendingString:@" user not logged in"];
    }
    
    email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
}

- (void)launchRateUs {
#ifdef INatAppStoreURL
    if ([[INatReachability sharedClient] isNetworkReachable]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:INatAppStoreURL]];
    } else {
        [self networkUnreachableAlert];
    }
#else
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Cannot rate", nil)
                                                                   message:NSLocalizedString(@"No App Store URL configured", nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
#endif
}

- (void)launchCredits {
    VTAcknowledgementsViewController *creditsVC = [VTAcknowledgementsViewController acknowledgementsViewController];
    
    NSString *credits = [NSString stringWithFormat:@"%@\n\n%@\n\n%@\n\n%@\n\n%@\n\n%@",
                         NSLocalizedString(@"Designed and built by iNaturalist at the California Academy of Sciences, with support from the Encyclopedia of Life. ", @"funding thank yous"),
                         NSLocalizedString(@"iNaturalist is made by every single person who participates in our community. The people who build the software, maintain our infrastructure, and foster collaborations are Joelle Belmonte, Yaron Budowski, Tony Iwane, Patrick Leary, Scott Loarie, Alex Shepard, and Ken-ichi Ueda.", @"inat core team, alphabetically"),
                         NSLocalizedString(@"Special thanks to NVIDIA and Visipedia for technical assistance with iNaturalist's computer vision suggestions.", @"vision assistance"),
                         NSLocalizedString(@"iNaturalist uses Glyphish icons by Joseph Wain, ionicons by Ben Sperry, and icons by Luis Prado and Roman Shlyakov from the Noun Project. iNaturalist is also deeply grateful to the Cocoapods community, and to the contributions of our own open source community. See https://github.com/inaturalist/INaturalistIOS.", @"open source contributions"),
                         NSLocalizedString(@"We are grateful for the translation assistance provided by the crowdin.com community, especially: Catherine B, Vladimir Belash, cgalindo, danieleseglie, Eduardo Martínez, naofum, Foss, jacquesboivin, Sungmin Ji, katunchik, NCAA, oarazy, sudachi, T.O, testamorta, and vilseskog. To join the iNaturalist iOS translation team, please visit https://crowdin.com/project/inaturalistios.", @"inat ios translators with more than 200 strings contributed, alphabetically"),
                         @"IUCN category II places provided by IUCN and UNEP-WCMC (2015), The World Database on Protected Areas (WDPA) [On-line], [11/2014], Cambridge, UK: UNEP-WCMC. Available at: www.protectedplanet.net."];

    creditsVC.headerText = credits;
    UILabel *label = creditsVC.tableView.tableHeaderView.subviews.firstObject;
    label.textAlignment = NSTextAlignmentLeft;
    
    [self.navigationController pushViewController:creditsVC animated:YES];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(initUI)
                                                 name:kUserLoggedInNotificationName
                                               object:nil];

    self.partnerController = [[PartnerController alloc] init];
    
    self.title = NSLocalizedString(@"Settings", @"Title for the settings screen.");
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initUI];
    
    // don't show a toolbar in Settings
    [self.navigationController setToolbarHidden:YES];
}

- (void)selectedPartner:(Partner *)partner {
    __weak typeof(self)weakSelf = self;
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate.loginController loggedInUserSelectedPartner:partner
                                                  completion:^{
                                                      [[Analytics sharedClient] event:kAnalyticsEventSettingsNetworkChangeCompleted];
                                                      [weakSelf.tableView reloadData];
                                                  }];
}

#pragma mark - UISwitch target

- (void)settingSwitched:(UISwitch *)switcher {
    NSString *key;
    
    if (switcher.tag == AutocompleteNamesSwitchTag)
        key = kINatAutocompleteNamesPrefKey;
    else if (switcher.tag == AutouploadSwitchTag)
        key = kInatAutouploadPrefKey;
    else if (switcher.tag == SuggestionsSwitchTag)
        key = kINatSuggestionsPrefKey;
    
    if (key) {
        NSString *analyticsEvent;
        
        if (switcher.isOn) {
            analyticsEvent = kAnalyticsEventSettingEnabled;
        } else {
            analyticsEvent = kAnalyticsEventSettingDisabled;
        }
        
        [[Analytics sharedClient] event:analyticsEvent
                         withProperties:@{ @"setting": key }];
        
        [[NSUserDefaults standardUserDefaults] setBool:switcher.isOn forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        if ([key isEqualToString:kInatAutouploadPrefKey]) {
            INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
            UploadManager *uploadManager = appDelegate.loginController.uploadManager;
            if (switcher.isOn) {
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
                if (uploadManager.isUploading) {
                    [uploadManager cancelSyncsAndUploads];
                }
            }
        }
    }
}

#pragma mark - UITableView
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 4 && indexPath.row == 0) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@",
                               self.versionText,
                               [[ImageStore sharedImageStore] usageStatsString]];
        cell.textLabel.textAlignment = NSTextAlignmentNatural;
        cell.backgroundView = nil;
    } else if (indexPath.section == 0) {
        INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];

        if (indexPath.row == 0) {
            // username cell
            cell.textLabel.text = NSLocalizedString(@"Username", nil);
            INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
            if (appDelegate.loginController.isLoggedIn) {
                cell.detailTextLabel.text = appDelegate.loginController.fetchMe.login;
            } else {
                cell.detailTextLabel.text = NSLocalizedString(@"Not Logged In", nil);
            }
        } else {
            // account action (sign in / sign out) cell
            cell.textLabel.textColor = [UIColor inatTint];
            if (appDelegate.loginController.isLoggedIn) {
                cell.textLabel.text = NSLocalizedString(@"Sign out",nil);
            } else {
                cell.textLabel.text = NSLocalizedString(@"Log In / Sign Up",nil);
            }
        }
    }
    else if (indexPath.section == 1) {
        cell.userInteractionEnabled = YES;
        
        if (indexPath.item == 0) {
            // do nothing
        } else if (indexPath.item < 4) {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            UILabel *autoNameLabel = (UILabel *)[cell.contentView viewWithTag:AutocompleteNamesLabelTag];
            if (autoNameLabel) {
                autoNameLabel.textAlignment = NSTextAlignmentNatural;
            }
            UILabel *autouploadLabel = (UILabel *)[cell.contentView viewWithTag:AutouploadLabelTag];
            if (autouploadLabel) {
                autouploadLabel.textAlignment = NSTextAlignmentNatural;
            }
            
            UISwitch *switcher;
            if (![cell viewWithTag:100 + indexPath.item]) {
                
                switcher = [[UISwitch alloc] initWithFrame:CGRectZero];
                switcher.translatesAutoresizingMaskIntoConstraints = NO;
                switcher.tag = 100 + indexPath.item;
                switcher.enabled = YES;
                [switcher addTarget:self
                             action:@selector(settingSwitched:)
                   forControlEvents:UIControlEventValueChanged];
                
                [cell.contentView addSubview:switcher];
                
                [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[switcher]-15-|"
                                                                             options:0
                                                                             metrics:0
                                                                               views:@{ @"switcher": switcher }]];
                [cell addConstraint:[NSLayoutConstraint constraintWithItem:switcher
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:cell.contentView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1.0f
                                                                  constant:0.0f]];
            } else {
                switcher = (UISwitch *)[cell viewWithTag:100 + indexPath.item];
            }
            
            if (switcher.tag == AutocompleteNamesSwitchTag)
                switcher.on = [[NSUserDefaults standardUserDefaults] boolForKey:kINatAutocompleteNamesPrefKey];
            else if (switcher.tag == AutouploadSwitchTag)
                switcher.on = [[NSUserDefaults standardUserDefaults] boolForKey:kInatAutouploadPrefKey];
            else if (switcher.tag == SuggestionsSwitchTag)
                switcher.on = [[NSUserDefaults standardUserDefaults] boolForKey:kINatSuggestionsPrefKey];
            
        } else {
            // iNaturalist Network setting
            
            // main text in black
            cell.textLabel.enabled = YES;
            
            // put user object changing site id
            INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
            User *me = [appDelegate.loginController fetchMe];
            UILabel *detailTextLabel = (UILabel *)[cell viewWithTag:NetworkDetailLabelTag];
            [self setupConstraintsForNetworkCell:cell];
            if (me) {
                Partner *p = [self.partnerController partnerForSiteId:me.siteId.integerValue];
                detailTextLabel.text = p.name;
            } else {
                detailTextLabel.text = @"iNaturalist";
            }
            
        }
    }
    else if (indexPath.section == 2) {  // Handles help section
        cell.textLabel.textAlignment = NSTextAlignmentNatural;
    }
    else if (indexPath.section == 3) {  // Handles Acknowledgements section
        cell.textLabel.textAlignment = NSTextAlignmentNatural;
    }
}

- (void)choseToChangeNetworkPartner {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
    User *me = [appDelegate.loginController fetchMe];
    if (!me) { return; }
    
    NSArray *partnerNames = [self.partnerController.partners bk_map:^id(Partner *p) {
        return p.name;
    }];
    
    Partner *currentPartner = [self.partnerController partnerForSiteId:me.siteId.integerValue];
    
    __weak typeof(self) weakSelf = self;
    [[[ActionSheetStringPicker alloc] initWithTitle:NSLocalizedString(@"Choose iNat Network", "title of inat network picker")
                                               rows:partnerNames
                                   initialSelection:[partnerNames indexOfObject:currentPartner.name]
                                          doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
                                              __strong typeof(weakSelf) strongSelf = weakSelf;
                                              // update base url
                                              Partner *p = strongSelf.partnerController.partners[selectedIndex];
                                              if (![p isEqual:currentPartner]) {
                                                  [weakSelf selectedPartner:p];
                                              }
                                          }
                                        cancelBlock:nil
                                             origin:self.view] showActionSheetPicker];
}

#pragma mark - UITableViewDataSource
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1) {
        if (indexPath.item == 0) {
            [self tappedUsername];
        } else if (indexPath.item == 4) {
			INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
			if (![appDelegate.loginController isLoggedIn]) {
				[self presentSignup];
            } else {
                [[Analytics sharedClient] event:kAnalyticsEventSettingsNetworkChangeBegan];
                // show SERIOUS alert
                NSString *alertMsg = NSLocalizedString(@"Changing your iNaturalist Network affiliation will alter some parts of the app, like what taxa appear in searches, but it will also allow the new network partner to view and download all of your data. Are you sure you want to do this?",
                                                       @"alert msg before changing the network affiliation.");
                NSString *cancelBtnMsg = NSLocalizedString(@"No, don't change my affiliation", @"cancel button before changing network affiliation.");
                NSString *continueBtnMsg = NSLocalizedString(@"Yes, change my affiliation", @"continue button before changing network affiliation.");
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warning", nil)
                                                                               message:alertMsg
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:cancelBtnMsg
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil]];
                [alert addAction:[UIAlertAction actionWithTitle:continueBtnMsg
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
                                                            [self choseToChangeNetworkPartner];
                                                        }]];
                [self.tabBarController presentViewController:alert animated:YES completion:nil];
            }
            
            return;
        } else {
            // show popover
            NSString *tooltipText;
            if (indexPath.item == 1) {
                // autocorrect
                tooltipText = NSLocalizedString(@"Enable to allow iOS to auto-correct and spell-check Species names.", @"tooltip text for autocorrect settings option.");
            } else if (indexPath.item == 2) {
                // automatically upload
                tooltipText = NSLocalizedString(@"Automatically upload new or edited content to iNaturalist.org",
                                                @"tooltip text for automatically upload option.");
            } else if (indexPath.item == 3) {
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
    } else if (indexPath.section == CreditsSection) {
        [self launchCredits];
        return;
    } else if (indexPath.section == 2) {
        if (indexPath.item == 0) {
            [self launchTutorial];
        } else if (indexPath.item == 1) {
            [self sendSupportEmail];
        } else if (indexPath.item == 2) {
            [self launchRateUs];
        }
    } else if (indexPath.section == 0) {
        INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
        if (indexPath.item == 0) {
            if ([appDelegate.loginController isLoggedIn]) {
                [self tappedUsername];
            } else {
                if ([[INatReachability sharedClient] isNetworkReachable]) {
                    [self presentSignup];
                } else {
                    [self networkUnreachableAlert];
                }
            }
        } else if (indexPath.item == 1) {
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

- (void)presentSignup {
    [[Analytics sharedClient] event:kAnalyticsEventNavigateOnboardingScreenLogin
                     withProperties:@{ @"via": @"settings" }];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Onboarding" bundle:nil];
    OnboardingLoginViewController *login = [storyboard instantiateViewControllerWithIdentifier:@"onboarding-login"];
    login.skippable = NO;
    [self presentViewController:login animated:YES completion:nil];
}

- (void)setupConstraintsForNetworkCell:(UITableViewCell *)cell{
    if(!cell.constraints.count){
        UILabel *detailTextLabel = (UILabel *)[cell viewWithTag:NetworkDetailLabelTag];
        detailTextLabel.textAlignment = NSTextAlignmentNatural;
        detailTextLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        UILabel *textLabel = (UILabel *)[cell viewWithTag:NetworkTextLabelTag];
        textLabel.translatesAutoresizingMaskIntoConstraints = NO;
        textLabel.textAlignment = NSTextAlignmentNatural;
        
        NSDictionary *views = @{@"textLabel":textLabel, @"detailTextLabel":detailTextLabel};
        
        [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-15-[textLabel]-[detailTextLabel]-|" options:0 metrics:0 views:views]];
        
        [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-11-[textLabel]-11-|" options:NSLayoutFormatAlignAllLeading metrics:0 views:views]];
        
        [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-11-[detailTextLabel]-11-|" options:NSLayoutFormatAlignAllTrailing metrics:0 views:views]];
    }
}


@end












