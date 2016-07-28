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
#import "SignupSplashViewController.h"
#import "INaturalistAppDelegate.h"
#import "INaturalistAppDelegate+TransitionAnimators.h"
#import "PartnerController.h"
#import "Partner.h"
#import "LoginController.h"
#import "UploadManager.h"
#import "UIColor+INaturalist.h"

static const int CreditsSection = 3;

static const int UsernameCellTag = 0;
static const int AccountActionCellTag = 1;
static const int TutorialActionCellTag = 2;
static const int ContactActionCellTag = 3;
static const int RateUsCellTag = 4;
static const int VersionCellTag = 5;

static const int NetworkDetailLabelTag = 14;
static const int NetworkTextLabelTag = 15;

// labels for settings switcher rows are 50 + row index
static const int AutocompleteNamesLabelTag = 50;
static const int AutouploadLabelTag = 51;

// setting switchers are 100 + row index
static const int AutocompleteNamesSwitchTag = 100;
static const int AutouploadSwitchTag = 101;

@interface SettingsViewController () <UIActionSheetDelegate> {
    UITapGestureRecognizer *tapAway;
    JDFTooltipView *tooltip;
    UIActionSheet *changeNetworkActionSheet;
}
@property PartnerController *partnerController;
@end

@implementation SettingsViewController

@synthesize versionText = _versionText;

- (void)initUI
{
    self.navigationController.navigationBar.translucent = NO;

    UITableViewCell *usernameCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITableViewCell *accountActionCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    UITableViewCell *tutorialActionCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
    UITableViewCell *contactActionCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:2]];
    UITableViewCell *rateUsActionCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:2]];
    usernameCell.tag = UsernameCellTag;
    accountActionCell.tag = AccountActionCellTag;
    tutorialActionCell.tag = TutorialActionCellTag;
    contactActionCell.tag = ContactActionCellTag;
    rateUsActionCell.tag = RateUsCellTag;
    
    
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    self.versionText = [NSString stringWithFormat:NSLocalizedString(@"%@, build %@",nil),
                        [info objectForKey:@"CFBundleShortVersionString"],
                        [info objectForKey:@"CFBundleVersion"]];
    
    [self.tableView reloadData];
}

- (void)clickedSignOut
{
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure?",nil)
                                                 message:NSLocalizedString(@"This will delete all your observations on this device.  It will not affect any observations you've uploaded to iNaturalist.",nil)
                                                delegate:self 
                                       cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                       otherButtonTitles:NSLocalizedString(@"Sign out",nil), nil];
    [av show];
}

- (void)signOut
{
    [[Analytics sharedClient] event:kAnalyticsEventLogout];
    
    [[[RKClient sharedClient] requestQueue] cancelAllRequests];

    [self localSignOut];
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate rebuildCoreData];
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
    [[NSUserDefaults standardUserDefaults] synchronize];
    
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
    
    // update UI
    [(INatUITabBarController *)self.tabBarController setObservationsTabBadge];
    [self initUI];
}

- (void)launchTutorial
{
    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateTutorial];
    
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
    
    gallery.finishedCallback = ^(NSUInteger currentIndex,UIImage *image,MHTransitionDismissMHGallery *interactiveTransition,MHGalleryViewMode viewMode){
        dispatch_async(dispatch_get_main_queue(), ^{
            [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateTutorial];
            [blockGallery dismissViewControllerAnimated:YES completion:nil];
        });
    };
    [self presentMHGalleryController:gallery animated:YES completion:nil];
}

- (void)sendSupportEmail
{
    NSString *email = [NSString stringWithFormat:@"mailto://help@inaturalist.org?cc=&subject=iNaturalist iPhone help: version %@", 
                       self.versionText];
    email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
}

- (void)launchRateUs {
#ifdef INatAppStoreURL
    if ([[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:INatAppStoreURL]];
    } else {
        [self networkUnreachableAlert];
    }
#else
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cannot rate", nil)
                                                    message:NSLocalizedString(@"No App Store URL configured", nil)
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil];
    [alert show];
#endif
}

- (void)launchCredits {
    [[Analytics sharedClient] event:kAnalyticsEventNavigateAcknowledgements];
    
    VTAcknowledgementsViewController *creditsVC = [VTAcknowledgementsViewController acknowledgementsViewController];
    
    NSString *credits = [NSString stringWithFormat:@"%@\n\n%@\n\n%@\n\n%@\n\n%@",
                         NSLocalizedString(@"Designed and built by iNaturalist at the California Academy of Sciences, with support from the Encyclopedia of Life. ", @"funding thank yous"),
                         NSLocalizedString(@"iNaturalist is made by every single person who participates in our community. The people who build the software, maintain our infrastructure, and foster collaborations are Joelle Belmonte, Patrick Leary, Scott Loarie, Alex Shepard, and Ken-ichi Ueda.", @"inat core team, alphabetically"),
                         NSLocalizedString(@"iNaturalist uses Glyphish icons by Joseph Wain, ionicons by Ben Sperry, and icons by Luis Prado and Roman Shlyakov from the Noun Project. iNaturalist is also deeply grateful to the Cocoapods community, and to the contributions of our own open source community. See https://github.com/inaturalist/INaturalistIOS.", @"open source contributions"),
                         NSLocalizedString(@"We are grateful for the translation assistance provided by the following members of the crowdin.com community: Carlos Alonso, Gabriel Fabiano Benzoni, cgalindo, Cecilia Juryung Chung, Claudine Cyr, eldadzz, jacquesboivin, harum koh, MinYoung Jang, Donggeun Lee, Angelo Loula, myerssusan, nagatowell, natleclaire, James Page, Juliana Gatti Pereira, sgravel8596, sudachi, T.O, testamorta, tiwamura, vilseskog, and vonmatter. To join the iNaturalist iOS translation team, please visit https://crowdin.com/project/inaturalistios.", @"inat ios translation team, alphabetically"),
                         @"IUCN category II places provided by IUCN and UNEP-WCMC (2015), The World Database on Protected Areas (WDPA) [On-line], [11/2014], Cambridge, UK: UNEP-WCMC. Available at: www.protectedplanet.net."];

    creditsVC.headerText = credits;
    UILabel *label = creditsVC.tableView.tableHeaderView.subviews.firstObject;
    label.textAlignment = NSTextAlignmentLeft;
    
    [self.navigationController pushViewController:creditsVC animated:YES];
}

- (void)networkUnreachableAlert
{
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                                 message:NSLocalizedString(@"Try again next time you're connected to the Internet.",nil)
                                                delegate:self 
                                       cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                       otherButtonTitles:nil];
    [av show];
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateSettings];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateSettings];
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
        cell.textLabel.text = self.versionText;
        cell.textLabel.textAlignment = NSTextAlignmentNatural;
        cell.backgroundView = nil;
        cell.tag = VersionCellTag;
        
    }
    else if (indexPath.section == 0) {
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

        if (indexPath.item < 2) {
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


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([actionSheet isEqual:changeNetworkActionSheet]) {
        if (buttonIndex == 0) {
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
    }
}

#pragma mark - UITableViewDataSource
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        if (indexPath.item == 2) {
            // so the user can select again
            [tableView deselectRowAtIndexPath:indexPath animated:NO];

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
                
                changeNetworkActionSheet = [[UIActionSheet alloc] initWithTitle:alertMsg
                                                                       delegate:self
                                                              cancelButtonTitle:cancelBtnMsg
                                                         destructiveButtonTitle:nil
                                                              otherButtonTitles:continueBtnMsg, nil];
                [changeNetworkActionSheet showFromTabBar:self.tabBarController.tabBar];
            }
            
            return;
        }
        // show popover
        NSString *tooltipText;
        if (indexPath.item == 0) {
            // autocorrect
            tooltipText = NSLocalizedString(@"Enable to allow iOS to auto-correct and spell-check Species names.", @"tooltip text for autocorrect settings option.");
        } else if (indexPath.item == 1) {
            // automatically upload
            tooltipText = NSLocalizedString(@"Automatically upload new or edited content to iNaturalist.org",
                                            @"tooltip text for automatically upload option.");
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
    } else if (indexPath.section == CreditsSection) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self launchCredits];
        return;
    }
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
	INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
	
    switch (cell.tag) {
        case UsernameCellTag:
			if ([appDelegate.loginController isLoggedIn]) {
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            } else {
                if ([[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
                    [self presentSignup];
                } else {
                    [self networkUnreachableAlert];
                }
            }
            break;
        case AccountActionCellTag:
			if ([appDelegate.loginController isLoggedIn]) {
	            [self clickedSignOut];
            } else {
                if ([[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
                    [self presentSignup];
                } else {
                    [self networkUnreachableAlert];
                }
            }
            break;
        case TutorialActionCellTag:
            [self launchTutorial];
            break;
        case ContactActionCellTag:
            [self sendSupportEmail];
            break;
        case RateUsCellTag:
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            [self launchRateUs];
            break;
        default:
            break;
    }
}

- (void)presentSignup {
    [[Analytics sharedClient] event:kAnalyticsEventNavigateSignupSplash
                     withProperties:@{ @"From": @"Settings" }];

    SignupSplashViewController *signup = [[SignupSplashViewController alloc] initWithNibName:nil bundle:nil];
    signup.cancellable = YES;
    signup.skippable = NO;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:signup];
    nav.delegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self signOut];
    } else {
        [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    }
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












