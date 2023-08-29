//
//  ExploreSearchViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/10/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKFoundationIcons.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <BlocksKit/BlocksKit.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <CoreLocation/CoreLocation.h>

#import "ExploreSearchViewController.h"
#import "ExploreMapViewController.h"
#import "ExploreGridViewController.h"
#import "ExploreListViewController.h"
#import "ExploreObservationsController.h"
#import "ExploreActiveSearchView.h"
#import "ExploreLocation.h"
#import "ExploreProject.h"
#import "ExploreUser.h"
#import "UIColor+ExploreColors.h"
#import "Taxon.h"
#import "TaxonPhoto.h"
#import "UIFont+ExploreFonts.h"
#import "UIImage+ExploreIconicTaxaImages.h"
#import "ExploreDisambiguator.h"
#import "ExploreSearchController.h"
#import "ExploreSearchView.h"
#import "AutocompleteSearchItem.h"
#import "ShortcutSearchItem.h"
#import "ExploreLeaderboardViewController.h"
#import "OnboardingLoginViewController.h"
#import "UIColor+INaturalist.h"
#import "LoginController.h"
#import "INaturalistAppDelegate.h"
#import "INatReachability.h"
#import "ExploreUserRealm.h"
#import "ExploreActiveSearchView.h"

@interface ExploreSearchViewController () <CLLocationManagerDelegate, ActiveSearchTextDelegate>
@property CLLocationManager *locationManager;
@property NSTimer *locationFetchTimer;
@property BOOL hasFulfilledLocationFetch;
@property BOOL isFetchingLocation;

@property UIBarButtonItem *leaderboardItem;
@property UIBarButtonItem *spinnerItem;
@property UIActivityIndicatorView *spinner;

@property ExploreSearchView *searchMenu;
@property ExploreActiveSearchView *activeSearchView;

@property ExploreMapViewController *mapVC;
@property ExploreGridViewController *gridVC;
@property ExploreListViewController *listVC;
@property ExploreObservationsController *observationsController;
@property ExploreSearchController *searchController;
@end


@implementation ExploreSearchViewController

// since we're coming out of a storyboard, -initWithCoder: is the initializer
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {

        if (@available(iOS 13.0, *)) {
            self.navigationController.tabBarItem.image = [UIImage systemImageNamed:@"map.fill"];
        } else {
            FAKIcon *compassInactive = [FAKIonIcons androidCompassIconWithSize:30];
            [compassInactive addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor]];
            self.navigationController.tabBarItem.image = [[compassInactive imageWithSize:CGSizeMake(30, 45)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];

            FAKIcon *compassActive = [FAKIonIcons androidCompassIconWithSize:30];
            [compassActive addAttribute:NSForegroundColorAttributeName value:[UIColor inatTint]];
            self.navigationController.tabBarItem.selectedImage = [[compassActive imageWithSize:CGSizeMake(30, 45)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];

        }
        
        self.navigationController.tabBarItem.title = NSLocalizedString(@"Explore", nil);
        
        UIBarButtonItem *search = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                                                                target:self
                                                                                action:@selector(searchPressed)];
        self.navigationItem.leftBarButtonItem = search;
        
        self.leaderboardItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Stats", @"Title for button in the explore tab that leads to the stats leaderboard.")
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(leaderboardPressed)];
        self.navigationItem.rightBarButtonItem = self.leaderboardItem;
        
        self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.spinnerItem = [[UIBarButtonItem alloc] initWithCustomView:self.spinner];
        
        
        self.observationsController = [[ExploreObservationsController alloc] init];
        self.observationsController.notificationDelegate = self;
        
        self.searchController = [[ExploreSearchController alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.activeSearchView = ({
        ExploreActiveSearchView *view = [ExploreActiveSearchView new];
        view.backgroundColor = [UIColor redColor];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        
        [view.removeActiveSearchButton addTarget:self
                                          action:@selector(removeSearchPressed)
                                forControlEvents:UIControlEventTouchUpInside];
        view.activeSearchTextDelegate = self;
        view.hidden = YES;
        
        view;
    });
    [self.view addSubview:self.activeSearchView];
    
    self.searchMenu = ({
        ExploreSearchView *view = [[ExploreSearchView alloc] initWithFrame:CGRectZero];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        
        __weak typeof(self) weakSelf = self;
        // autocomplete items
        AutocompleteSearchItem *critters = [AutocompleteSearchItem itemWithPredicate:AutocompletePredicateOrganisms
                                                                              action:^(NSString *searchText) {
            [weakSelf searchForTaxon:searchText];
            [weakSelf.searchMenu hideOptionSearch];
            if (weakSelf.observationsController.activeSearchPredicates.count > 0)
                [weakSelf showActiveSearch];
        }];
        AutocompleteSearchItem *people = [AutocompleteSearchItem itemWithPredicate:AutocompletePredicatePeople
                                                                            action:^(NSString *searchText) {
            [weakSelf searchForPerson:searchText];
            [weakSelf.searchMenu hideOptionSearch];
            if (weakSelf.observationsController.activeSearchPredicates.count > 0)
                [weakSelf showActiveSearch];
        }];
        AutocompleteSearchItem *locations = [AutocompleteSearchItem itemWithPredicate:AutocompletePredicateLocations
                                                                               action:^(NSString *searchText) {
            [weakSelf searchForLocation:searchText];
            [weakSelf.searchMenu hideOptionSearch];
            if (weakSelf.observationsController.activeSearchPredicates.count > 0)
                [weakSelf showActiveSearch];
        }];
        AutocompleteSearchItem *projects = [AutocompleteSearchItem itemWithPredicate:AutocompletePredicateProjects
                                                                              action:^(NSString *searchText) {
            [weakSelf searchForProject:searchText];
            [weakSelf.searchMenu hideOptionSearch];
            if (weakSelf.observationsController.activeSearchPredicates.count > 0)
                [weakSelf showActiveSearch];
        }];
        view.autocompleteItems = @[critters, people, locations, projects];
        
        // non-autocomplete shortcut items
        ShortcutSearchItem *nearMe = [ShortcutSearchItem itemWithTitle:NSLocalizedString(@"Find observations near me", nil)
                                                                action:^{
            [weakSelf searchForNearbyObservations];
            [weakSelf.searchMenu hideOptionSearch];
            if (weakSelf.observationsController.activeSearchPredicates.count > 0)
                [weakSelf showActiveSearch];
        }];
        
        ShortcutSearchItem *mine = [ShortcutSearchItem itemWithTitle:NSLocalizedString(@"Find my observations", nil)
                                                              action:^{
            [weakSelf.searchMenu hideOptionSearch];
            __strong typeof(weakSelf)strongSelf = weakSelf;
            INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
            if ([appDelegate.loginController isLoggedIn]) {
                [strongSelf searchForMyObservations];
                if (strongSelf.observationsController.activeSearchPredicates.count > 0)
                    [strongSelf showActiveSearch];
            } else {
                [strongSelf presentSignupPrompt:NSLocalizedString(@"You must be logged in to do that.",
                                                                  @"Unspecific signup prompt reason.")];
            }
        }];
        view.shortcutItems = @[nearMe, mine];
        
        
        view;
    });
    [self.view addSubview:self.searchMenu];
    
    // the active search view overlays on top
    // of all of the stuff in the container view
    self.overlayView = self.activeSearchView;
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // set up the map|grid|list selector
    self.mapVC = [[ExploreMapViewController alloc] initWithNibName:nil bundle:nil];
    self.mapVC.observationDataSource = self.observationsController;
    self.gridVC = [[ExploreGridViewController alloc] initWithNibName:nil bundle:nil];
    self.gridVC.observationDataSource = self.observationsController;
    self.listVC = [[ExploreListViewController alloc] initWithNibName:nil bundle:nil];
    self.listVC.observationDataSource = self.observationsController;
    self.viewControllers = @[self.mapVC, self.gridVC, self.listVC];
    
    // configure the segmented control
    [self.viewControllers bk_each:^(UIViewController *vc) {
        if ([vc conformsToProtocol:@protocol(ExploreViewControllerControlIcon)]) {
            [self.segmentedControl insertSegmentWithImage:[((id <ExploreViewControllerControlIcon>)vc) controlIcon]
                                                  atIndex:[self.viewControllers indexOfObject:vc]
                                                 animated:NO];
        }
    }];
    // force the navigation bar to re-layout since the segmented control has changed
    // doesn't happen automatically as of xcode8
    [self.navigationController.navigationBar setNeedsLayout];
    
    // display first item
    [self.segmentedControl setSelectedSegmentIndex:0];
    [self displayContentController:self.mapVC];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.activeSearchView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.activeSearchView.heightAnchor constraintEqualToConstant:50],
        [self.activeSearchView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.activeSearchView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        
        [self.searchMenu.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.searchMenu.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        [self.searchMenu.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.searchMenu.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    ]];
    
    // ios 15 nav bar appearance
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = [UIColor whiteColor];
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
            // do nothing
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        case kCLAuthorizationStatusNotDetermined:
        default:
            [self startLookingForCurrentLocationNotify:NO];
            break;
    }
}

- (void)presentSignupPrompt:(NSString *)reason {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Onboarding" bundle:nil];
    OnboardingLoginViewController *login = [storyboard instantiateViewControllerWithIdentifier:@"onboarding-login"];
    login.skippable = NO;
    [self presentViewController:login animated:YES completion:nil];
}

- (void)showActiveSearch {
    self.activeSearchView.activeSearchLabel.text = self.activeSearchText;
    self.activeSearchView.hidden = NO;
}

- (void)hideActiveSearch {
    self.activeSearchView.activeSearchLabel.text = nil;
    self.activeSearchView.hidden = YES;
}

#pragma mark - UIControl targets

- (void)leaderboardPressed {
    ExploreLeaderboardViewController *vc = [[ExploreLeaderboardViewController alloc] initWithNibName:nil bundle:nil];
    vc.observationsController = self.observationsController;
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)removeSearchPressed {
    [self hideActiveSearch];
    
    [self.observationsController removeAllSearchPredicates];
}

- (void)searchPressed {
    if ([self.searchMenu optionSearchIsActive]) {
        if (self.observationsController.activeSearchPredicates.count > 0) {
            [self showActiveSearch]; // implicitly hides option search
        } else {
            [self.searchMenu hideOptionSearch];
        }
    } else {
        [self.searchMenu showOptionSearch];
    }
}

#pragma mark - iNat API Calls

- (void)searchForMyObservations {
    
    if (![[INatReachability sharedClient] isNetworkReachable]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Cannot search iNaturalist.org", nil)
                                                                       message:NSLocalizedString(@"Network unavailable", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    // clear all active search predicates
    // since it's not built to remove them one at a time yet
    [self.observationsController removeAllSearchPredicatesUpdatingObservations:NO];
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    LoginController *login = [appDelegate loginController];
    ExploreUserRealm *me = [login meUserLocal];
    if (me) {
        ExploreUser *exploreMe = [[ExploreUser alloc] init];
        exploreMe.userId = me.userId;
        exploreMe.login = me.login;
        exploreMe.name = me.name;
        exploreMe.userIcon = me.userIcon;
        
        [self.observationsController addSearchPredicate:[ExploreSearchPredicate predicateForPerson:exploreMe]];
        [self showActiveSearch];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Oops", nil)
                                                                       message:NSLocalizedString(@"Can't search for your observations right now. Please try later.",
                                                                                                 @"Error message for when we can't retrieve your observations on Explore")
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)searchForNearbyObservations {
    
    if (![[INatReachability sharedClient] isNetworkReachable]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Cannot search iNaturalist.org", nil)
                                                                       message:NSLocalizedString(@"Network unavailable", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    self.hasFulfilledLocationFetch = NO;
    
    // clear all active search predicates
    // since it's not built to remove them one at a time yet
    [self.observationsController removeAllSearchPredicatesUpdatingObservations:NO];
    
    // no predicates, so hide the active search UI
    [self hideActiveSearch];
    
    // get observations near current location
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusNotDetermined:
            [self startLookingForCurrentLocationNotify:YES];
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [self startLookingForCurrentLocationNotify:YES];
            break;
            
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted: {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Permission denied", nil)
                                                                           message:NSLocalizedString(@"We don't have permission from iOS to use your location.", nil)
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
        default:
            break;
    }
}

- (void)searchForTaxon:(NSString *)text {
    
    if (![[INatReachability sharedClient] isNetworkReachable]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Cannot search iNaturalist.org", nil)
                                                                       message:NSLocalizedString(@"Network unavailable", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = NSLocalizedString(@"Searching for organisms...", nil);
    hud.removeFromSuperViewOnHide = YES;
    hud.dimBackground = YES;
    
    [self.searchController searchForTaxon:text completionHandler:^(NSArray *results, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        });
        
        if (error) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Cannot search iNaturalist.org", nil)
                                                                           message:error.localizedDescription
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            if (results.count == 0) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Oops", nil)
                                                                               message:NSLocalizedString(@"No such organisms found. :(", nil)
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            } else if (results.count == 1) {
                // observations controller will fetch observations using this predicate
                [self.observationsController addSearchPredicate:[ExploreSearchPredicate predicateForTaxon:results.firstObject]];
                
                [self showActiveSearch];
                
            } else {
                // allow the user to disambiguate the search results
                ExploreDisambiguator *disambiguator = [[ExploreDisambiguator alloc] init];
                disambiguator.title = NSLocalizedString(@"Which organism?", nil);
                disambiguator.searchOptions = results;
                
                __weak typeof(self)weakSelf = self;
                disambiguator.chosenBlock = ^void(id choice) {
                    // observations controller will fetch observations using this taxon
                    [self.observationsController addSearchPredicate:[ExploreSearchPredicate predicateForTaxon:(ExploreTaxon *)choice]];
                    
                    __strong typeof(weakSelf)strongSelf = weakSelf;
                    [strongSelf showActiveSearch];
                };
                
                // dispatch after a bit to allow the hud to finish animating dismissal
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [disambiguator presentDisambiguationAlert];
                });
            }
        }
    }];
    
}

- (void)searchForPerson:(NSString *)text {
    
    if (![[INatReachability sharedClient] isNetworkReachable]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Cannot search iNaturalist.org", nil)
                                                                       message:NSLocalizedString(@"Network unavailable", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = NSLocalizedString(@"Searching for people...", nil);
    hud.removeFromSuperViewOnHide = YES;
    hud.dimBackground = YES;
    
    [self.searchController searchForPerson:text completionHandler:^(NSArray *results, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        });
        
        if (error) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Cannot search iNaturalist.org", nil)
                                                                           message:error.localizedDescription
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            if (results.count == 0) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Oops", nil)
                                                                               message:NSLocalizedString(@"No such person found. :(", nil)
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            } else if (results.count == 1) {
                // observations controller will fetch observations using this predicate
                [self.observationsController addSearchPredicate:[ExploreSearchPredicate predicateForPerson:results.firstObject]];
                
                [self showActiveSearch];
                
            } else {
                ExploreDisambiguator *disambiguator = [[ExploreDisambiguator alloc] init];
                disambiguator.title = NSLocalizedString(@"Which person?", nil);
                disambiguator.searchOptions = results;
                
                __weak typeof(self)weakSelf = self;
                disambiguator.chosenBlock = ^void(id choice) {
                    __strong typeof(weakSelf)strongSelf = weakSelf;
                    
                    // observations controller will fetch observations using this predicate
                    [strongSelf.observationsController addSearchPredicate:[ExploreSearchPredicate predicateForPerson:(ExploreUser *)choice]];
                    
                    [strongSelf showActiveSearch];
                };
                // dispatch after a bit to allow the hud to finish animating dismissal
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [disambiguator presentDisambiguationAlert];
                });
            }
        }
    }];
}

- (void)searchForLocation:(NSString *)text {
    
    if (![[INatReachability sharedClient] isNetworkReachable]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Cannot search iNaturalist.org", nil)
                                                                       message:NSLocalizedString(@"Network unavailable", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = NSLocalizedString(@"Searching for place...", nil);
    hud.removeFromSuperViewOnHide = YES;
    hud.dimBackground = YES;
    
    [self.searchController searchForLocation:text completionHandler:^(NSArray *results, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        });
        
        if (error) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Cannot search iNaturalist.org", nil)
                                                                           message:error.localizedDescription
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            // filter out garbage locations
            NSArray *validPlaces = [results bk_select:^BOOL(ExploreLocation *location) {
                // all administrative places are valid
                if (location.adminLevel) { return YES; }
                // all open spaces (parks) are valid
                if (location.type == 100) { return YES; }
                // everything else is invalid
                return NO;
            }];
            
            if (validPlaces.count == 0) {
                CLGeocoder *geocoder = [[CLGeocoder alloc] init];
                [geocoder geocodeAddressString:text
                                      inRegion:nil  // if we're auth'd for location svcs, uses the user's location as the region
                             completionHandler:^(NSArray *placemarks, NSError *error) {
                    if (error.code == kCLErrorNetwork) {
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Cannot search iNaturalist.org", nil)
                                                                                       message:NSLocalizedString(@"Please try again in a few moments.", @"Error message for the user, when the geocoder is telling us to slow down.")
                                                                                preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                                  style:UIAlertActionStyleCancel
                                                                handler:nil]];
                        [self presentViewController:alert animated:YES completion:nil];
                    } else {
                        if (placemarks.count == 0) {
                            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Oops", nil)
                                                                                           message:NSLocalizedString(@"No such place found. :(", nil)
                                                                                    preferredStyle:UIAlertControllerStyleAlert];
                            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                                      style:UIAlertActionStyleCancel
                                                                    handler:nil]];
                            [self presentViewController:alert animated:YES completion:nil];
                        } else {
                            CLPlacemark *place = placemarks.firstObject;
                            [self.mapVC mapShouldZoomToCoordinates:place.location.coordinate showUserLocation:YES];
                        }
                    }
                }];
            } else if (validPlaces.count == 1) {
                // observations controller will fetch observations using this predicate
                [self.observationsController addSearchPredicate:[ExploreSearchPredicate predicateForLocation:(ExploreLocation *)validPlaces.firstObject]];
                
                [self showActiveSearch];
                
            } else {
                ExploreDisambiguator *disambiguator = [[ExploreDisambiguator alloc] init];
                disambiguator.title = NSLocalizedString(@"Which place?", nil);
                disambiguator.searchOptions = results;
                
                __weak typeof(self)weakSelf = self;
                disambiguator.chosenBlock = ^void(id choice) {
                    __strong typeof(weakSelf)strongSelf = weakSelf;
                    
                    // observations controller will fetch observations using this predicate
                    [strongSelf.observationsController addSearchPredicate:[ExploreSearchPredicate predicateForLocation:(ExploreLocation *)choice]];
                    
                    [strongSelf showActiveSearch];
                };
                // dispatch after a bit to allow the hud to finish animating dismissal
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [disambiguator presentDisambiguationAlert];
                });
            }
        }
    }];
    
}

- (void)searchForProject:(NSString *)text {
    
    if (![[INatReachability sharedClient] isNetworkReachable]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Cannot search iNaturalist.org", nil)
                                                                       message:NSLocalizedString(@"Network unavailable", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = NSLocalizedString(@"Searching for project...", nil);
    hud.removeFromSuperViewOnHide = YES;
    hud.dimBackground = YES;
    
    [self.searchController searchForProject:text completionHandler:^(NSArray *results, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        });
        
        if (error) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Cannot search iNaturalist.org", nil)
                                                                           message:error.localizedDescription
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            if (results.count == 0) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Oops", nil)
                                                                               message:NSLocalizedString(@"No such project found. :(", nil)
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            } else if (results.count == 1) {
                // observations controller will fetch observations using this predicate
                [self.observationsController addSearchPredicate:[ExploreSearchPredicate predicateForProject:results.firstObject]];
                
                [self showActiveSearch];
                
            } else {
                ExploreDisambiguator *disambiguator = [[ExploreDisambiguator alloc] init];
                disambiguator.title = NSLocalizedString(@"Which project?", nil);
                disambiguator.searchOptions = results;
                
                __weak typeof(self)weakSelf = self;
                disambiguator.chosenBlock = ^void(id choice) {
                    __strong typeof(weakSelf)strongSelf = weakSelf;
                    
                    // observations controller will fetch observations using this predicate
                    [strongSelf.observationsController addSearchPredicate:[ExploreSearchPredicate predicateForProject:(ExploreProject *)choice]];
                    
                    [strongSelf showActiveSearch];
                };
                // dispatch after a bit to allow the hud to finish animating dismissal
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [disambiguator presentDisambiguationAlert];
                });
            }
        }
    }];
}


#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    });
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Location Fetch Error", nil)
                                                                   message:error.localizedDescription
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
    self.isFetchingLocation = NO;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if (self.hasFulfilledLocationFetch)
        return;
    
    self.isFetchingLocation = NO;
    CLLocation *recentLocation = locations.lastObject;
    
    [self.locationFetchTimer invalidate];
    
    [self.locationManager stopUpdatingLocation];
    
    // one location fetch per user interaction with the "find observations near me" menu item
    if (!self.hasFulfilledLocationFetch) {
        self.hasFulfilledLocationFetch = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        });
        
        [self.mapVC mapShouldZoomToCoordinates:recentLocation.coordinate showUserLocation:YES];
    }
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (self.hasFulfilledLocationFetch)
        return;
    
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusNotDetermined:
            return;
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [self startLookingForCurrentLocationNotify:NO];
            break;
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted: {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            });
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Permission denied", nil)
                                                                           message:NSLocalizedString(@"We don't have permission from iOS to use your location.", nil)
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
        default:
            break;
    }
}

#pragma mark - Location Manager helpers

- (void)startLookingForCurrentLocationNotify:(BOOL)shouldNotify {
    if (self.isFetchingLocation)
        return;
    
    if (self.hasFulfilledLocationFetch)
        return;
    
    self.isFetchingLocation = YES;
    self.locationManager = [[CLLocationManager alloc] init];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        // request will start over
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = 1000;
    [self.locationManager stopUpdatingLocation];
    [self.locationManager startUpdatingLocation];
    
    if (shouldNotify) {
        // this may take a moment
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = NSLocalizedString(@"Finding your location...", nil);
        hud.removeFromSuperViewOnHide = YES;
        hud.dimBackground = YES;
    }
    
    self.locationFetchTimer = [NSTimer bk_scheduledTimerWithTimeInterval:15.0f
                                                              block:^(NSTimer *timer) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        });
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Timeout", nil)
                                                                       message:NSLocalizedString(@"Unable to find location", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        
        [self.locationManager stopUpdatingLocation];
        self.locationManager = nil;
        self.isFetchingLocation = NO;
    }
                                                            repeats:NO];
}



#pragma mark ActiveSearchText delegate

- (NSString *)activeSearchText {
    return self.observationsController.combinedColloquialSearchPhrase;
}

#pragma mark - ExploreObsNotificationDelegate

- (void)startedObservationFetch {
    [self.spinner startAnimating];
    self.navigationItem.rightBarButtonItem = self.spinnerItem;
}

- (void)finishedObservationFetch {
    if (!self.observationsController.isFetching) {
        // set the right bar button item to the reload button
        self.navigationItem.rightBarButtonItem = self.leaderboardItem;
        // stop the progress view
        [self.spinner stopAnimating];
    }
}

- (void)failedObservationFetch:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    });
    
    NSString *title = NSLocalizedString(@"Error Fetching Observations", nil);
    if (error.code == ObsFetchEmptyCode) {
        // not technically an error, so just show the message
        title = nil;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:error.localizedDescription
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
    
    // set the right bar button item to the reload button
    self.navigationItem.rightBarButtonItem = self.leaderboardItem;
    // stop the progress view
    [self.spinner stopAnimating];
}

@end
