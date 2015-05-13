//
//  SettingsViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/27/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>
#import <VTAcknowledgementsViewController/VTAcknowledgementsViewController.h>
#import <JDFTooltips/JDFTooltips.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <MHVideoPhotoGallery/MHGalleryController.h>
#import <MHVideoPhotoGallery/MHGallery.h>
#import <MHVideoPhotoGallery/MHTransitionDismissMHGallery.h>

#import "SettingsViewController.h"
#import "LoginViewController.h"
#import "Observation.h"
#import "ObservationPhoto.h"
#import "ProjectUser.h"
#import "ProjectObservation.h"
#import "Comment.h"
#import "Identification.h"
#import "User.h"
#import "DeletedRecord.h"
#import "INatUITabBarController.h"
#import "GTMOAuth2Authentication.h"
#import "NXOAuth2.h"
#import "Analytics.h"


static const int CreditsSection = 3;

static const int UsernameCellTag = 0;
static const int AccountActionCellTag = 1;
static const int TutorialActionCellTag = 2;
static const int ContactActionCellTag = 3;
static const int RateUsCellTag = 4;
static const int VersionCellTag = 5;

static const int AutocompleteNamesSwitchTag = 10;
static const int CategorizeNewObsSwitchTag = 11;

@interface SettingsViewController () {
    UITapGestureRecognizer *tapAway;
    JDFTooltipView *tooltip;
}
@end

@implementation SettingsViewController

@synthesize versionText = _versionText;

- (void)initUI
{
    self.navigationController.navigationBar.translucent = NO;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
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
    
    if ([defaults objectForKey:INatUsernamePrefKey] || [defaults objectForKey:INatTokenPrefKey]) {
        usernameCell.detailTextLabel.text = [defaults objectForKey:INatUsernamePrefKey];
        accountActionCell.textLabel.text = NSLocalizedString(@"Sign out",nil);
    } else {
        usernameCell.detailTextLabel.text = NSLocalizedString(@"Unknown",nil);
        accountActionCell.textLabel.text = NSLocalizedString(@"Sign in",nil);
    }
    
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    self.versionText = [NSString stringWithFormat:NSLocalizedString(@"Version %@, build %@",nil),
                        [info objectForKey:@"CFBundleShortVersionString"],
                        [info objectForKey:@"CFBundleVersion"]];
    
    [self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"%@ %@ %@",segue, segue.identifier , [segue identifier]);
    if ([segue.identifier compare: @"SignInFromSettingsSegue"] == NSOrderedSame) {
        [[Analytics sharedClient] event:kAnalyticsEventNavigateLogin
                         withProperties:@{ @"from": @"Settings" }];
        LoginViewController *vc = (LoginViewController *)[segue.destinationViewController topViewController];
        [vc setDelegate:self];
    }
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
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Signing out...",nil)];
        
    for (UIViewController *vc in self.tabBarController.viewControllers) {
        if ([vc isKindOfClass:UINavigationController.class]) {
            [(UINavigationController *)vc popToRootViewControllerAnimated:NO];
        }
    }
    
	[Comment deleteAll];
	[Identification deleteAll];
	[User deleteAll];
    [Observation deleteAll];
	[ObservationPhoto deleteAll];
    [ProjectUser deleteAll];
    [ProjectObservation deleteAll]; 
    for (DeletedRecord *dr in [DeletedRecord allObjects]) {
         [dr deleteEntity];
    }
    NSError *error = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
    [self localSignOut];
    [SVProgressHUD showSuccessWithStatus:nil];
}

- (void)localSignOut
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([[GPPSignIn sharedInstance] hasAuthInKeychain]) [[GPPSignIn sharedInstance] disconnect];
    [defaults removeObjectForKey:INatUsernamePrefKey];
    [defaults removeObjectForKey:INatPasswordPrefKey];
    [defaults removeObjectForKey:INatTokenPrefKey];
    [defaults synchronize];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [RKClient.sharedClient setUsername:nil];
    [RKClient.sharedClient setPassword:nil];
    NXOAuth2AccountStore *sharedStore = [NXOAuth2AccountStore sharedStore];
    for (NXOAuth2Account *account in sharedStore.accounts) {
        [sharedStore removeAccount:account];
    }
    [(INatUITabBarController *)self.tabBarController setObservationsTabBadge];
    [self initUI];
}

- (void)launchTutorial
{
    NSString *curLang = [[NSLocale preferredLanguages] objectAtIndex:0];

    NSMutableArray *tutorialImages = [NSMutableArray array];
    for (int i = 1; i <= 7; i++) {
        NSURL *tutorialItemUrl = [[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"tutorial%d%@", i, curLang]
                                                         withExtension:@"png"];
        if (!tutorialItemUrl) {
            // if we don't have tutorial files for the user's preferred language,
            // default to english
            tutorialItemUrl = [[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"tutorial%den", i]
                                                      withExtension:@"png"];
        }
        
        // be defensive
        if (tutorialItemUrl) {
            [tutorialImages addObject:tutorialItemUrl];
        }
    }
    NSArray *galleryData = [tutorialImages bk_map:^id(NSURL *url) {
        return [MHGalleryItem itemWithURL:url.absoluteString galleryType:MHGalleryTypeImage];
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
                         NSLocalizedString(@"iNaturalist uses Glyphish icons by Joseph Wain, ionicons by Ben Sperry, and a Binoculars icon by Luis Prado from the Noun Project. iNaturalist is also deeply grateful to the Cocoapods community.", @"open source contributions"),
                         NSLocalizedString(@"We are grateful for the translation assistance provided by the following members of the crowdin.com community: Gabriel Fabiano Benzoni, cgalindo, Claudine Cyr, jacquesboivin, harum koh, myerssusan, nagatowell, Juliana Gatti Pereira, sgravel8596, sudachi, T.O, testamorta, tiwamura, vilseskog, and vonmatter. To join the iNaturalist iOS translation team, please visit https://crowdin.com/project/inaturalistios.", @"inat ios translation team, alphabetically"),
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
    
    self.title = NSLocalizedString(@"Settings", @"Title for the settings screen.");
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

#pragma mark - UISwitch target

- (void)settingSwitched:(UISwitch *)switcher {
    NSString *key;
    
    if (switcher.tag == AutocompleteNamesSwitchTag)
        key = kINatAutocompleteNamesPrefKey;
    else if (switcher.tag == CategorizeNewObsSwitchTag)
        key = kInatCategorizeNewObsPrefKey;
    
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
    }
}

#pragma mark - UITableView
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 4 && indexPath.row == 0) {
        cell.textLabel.text = self.versionText;
        cell.backgroundView = nil;
        cell.tag = VersionCellTag;
        
    } else if (indexPath.section == 1) {
        cell.userInteractionEnabled = YES;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UISwitch *switcher;
        if (![cell viewWithTag:10 + indexPath.item]) {
            
            switcher = [[UISwitch alloc] initWithFrame:CGRectZero];
            switcher.translatesAutoresizingMaskIntoConstraints = NO;
            switcher.tag = 10 + indexPath.item;
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
            switcher = (UISwitch *)[cell viewWithTag:10 + indexPath.item];
        }
        
        if (switcher.tag == AutocompleteNamesSwitchTag)
            switcher.on = [[NSUserDefaults standardUserDefaults] boolForKey:kINatAutocompleteNamesPrefKey];
        else if (switcher.tag == CategorizeNewObsSwitchTag)
            switcher.on = [[NSUserDefaults standardUserDefaults] boolForKey:kInatCategorizeNewObsPrefKey];
        
    }
}

#pragma mark - UITableViewDataSource
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // do nothing when tapping app settings
    if (indexPath.section == 1) {
        // show popover
        NSString *tooltipText;
        if (indexPath.item == 0) {
            // autocorrect
            tooltipText = NSLocalizedString(@"Enable to allow iOS to auto-correct and spell-check Species names.", @"tooltip text for autocorrect settings option.");
        } else if (indexPath.item == 1) {
            // skip categorization
            tooltipText = NSLocalizedString(@"Enable to make a quick, initial identification from high-level taxa when making a new observation.", @"tooltip text for skip categorization option.");
        }
        
        tooltip = [[JDFTooltipView alloc] initWithTargetView:[[tableView cellForRowAtIndexPath:indexPath] viewWithTag:10+indexPath.item]
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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    switch (cell.tag) {
        case UsernameCellTag:
            if ([defaults objectForKey:INatUsernamePrefKey] || [defaults objectForKey:INatTokenPrefKey]) {
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            } else {
                if ([[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
                    [self performSegueWithIdentifier:@"SignInFromSettingsSegue" sender:self];
                } else {
                    [self networkUnreachableAlert];
                }
            }
            break;
        case AccountActionCellTag:
            if ([defaults objectForKey:INatUsernamePrefKey]|| [defaults objectForKey:INatTokenPrefKey]) {
                [self clickedSignOut];
            } else {
                if ([[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
                    [self performSegueWithIdentifier:@"SignInFromSettingsSegue" sender:self];
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


#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self signOut];
    } else {
        [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    }
}

#pragma mark - loginViewController Delegate
- (void)loginViewControllerDidLogIn:(LoginViewController *)controlle{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:INatUsernamePrefKey] || [defaults objectForKey:INatTokenPrefKey]) {
        UITableViewCell *usernameCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        usernameCell.detailTextLabel.text = [defaults objectForKey:INatUsernamePrefKey];
        [self.tableView reloadData];
    }
}

@end
