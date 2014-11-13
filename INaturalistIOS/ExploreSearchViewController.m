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
#import <SVProgressHUD/SVProgressHUD.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import "ExploreSearchViewController.h"

#import "ExploreMapViewController.h"
#import "ExploreGridViewController.h"
#import "ExploreListViewController.h"
#import "ExploreObservationsController.h"
#import "ExploreActiveSearchView.h"
#import "ExploreLocation.h"
#import "ExploreMappingProvider.h"
#import "ExploreProject.h"
#import "ExplorePerson.h"
#import "ExploreSearchCompleteCell.h"
#import "UIColor+ExploreColors.h"
#import "Analytics.h"
#import "Taxon.h"
#import "TaxonPhoto.h"
#import "ExploreSearchResultsCell.h"
#import "UIFont+ExploreFonts.h"
#import "UIImage+ExploreIconicTaxaImages.h"
#import "ExploreDisambiguator.h"
#import "ExploreSearchController.h"
#import "ExploreSearchView.h"
#import "AutocompleteSearchItem.h"
#import "ShortcutSearchItem.h"


@interface ExploreSearchViewController () <CLLocationManagerDelegate, ActiveSearchTextDelegate> {
    ExploreObservationsController *observationsController;
    
    ExploreSearchView *searchMenu;
    
    CLLocationManager *locationManager;
    
    NSTimer *locationFetchTimer;
    BOOL hasFulfilledLocationFetch;
    BOOL isFetchingLocation;
    
    ExploreMapViewController *mapVC;
    ExploreGridViewController *gridVC;
    ExploreListViewController *listVC;
    
    ExploreSearchController *searchController;
}

@end


@implementation ExploreSearchViewController

// since we're coming out of a storyboard, -initWithCoder: is the initializer
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        
        self.navigationController.tabBarItem.image = ({
            FAKIcon *worldOutline = [FAKIonIcons ios7WorldOutlineIconWithSize:35];
            [worldOutline addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
            [worldOutline imageWithSize:CGSizeMake(34, 45)];
        });
        
        self.navigationController.tabBarItem.selectedImage =({
            FAKIcon *worldFilled = [FAKIonIcons ios7WorldIconWithSize:35];
            [worldFilled addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
            [worldFilled imageWithSize:CGSizeMake(34, 45)];
        });
        
        self.navigationController.tabBarItem.title = @"Explore";
        
        observationsController = [[ExploreObservationsController alloc] init];
        searchController = [[ExploreSearchController alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // nav bar ui
    UIBarButtonItem *search = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                                                            target:self
                                                                            action:@selector(searchPressed)];
    self.navigationItem.leftBarButtonItem = search;
    
    UIBarButtonItem *refresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                             target:self
                                                                             action:@selector(refreshPressed)];
    self.navigationItem.rightBarButtonItem = refresh;
    
    searchMenu = ({
        ExploreSearchView *view = [[ExploreSearchView alloc] initWithFrame:CGRectZero];
        view.translatesAutoresizingMaskIntoConstraints = NO;
          
        // autocomplete items
        AutocompleteSearchItem *critters = [AutocompleteSearchItem itemWithPredicate:@"critters"
                                                                              action:^(NSString *searchText) {
                                                                                  [self searchForTaxon:searchText];
                                                                                  [searchMenu showActiveSearch];
                                                                              }];
        AutocompleteSearchItem *people = [AutocompleteSearchItem itemWithPredicate:@"people"
                                                                            action:^(NSString *searchText) {
                                                                                [self searchForPerson:searchText];
                                                                                [searchMenu showActiveSearch];
                                                                            }];
        AutocompleteSearchItem *locations = [AutocompleteSearchItem itemWithPredicate:@"locations"
                                                                               action:^(NSString *searchText) {
                                                                                   [self searchForLocation:searchText];
                                                                                   [searchMenu showActiveSearch];
                                                                               }];
        AutocompleteSearchItem *projects = [AutocompleteSearchItem itemWithPredicate:@"projects"
                                                                              action:^(NSString *searchText) {
                                                                                  [self searchForProject:searchText];
                                                                                  [searchMenu showActiveSearch];
                                                                              }];
        view.autocompleteItems = @[critters, people, locations, projects];
        
        // non-autocomplete shortcut items
        ShortcutSearchItem *nearMe = [ShortcutSearchItem itemWithTitle:@"Find observations near me"
                                                                action:^{
                                                                    [self searchForNearbyObservations];
                                                                    [searchMenu hideOptionSearch];
                                                                }];
        ShortcutSearchItem *mine = [ShortcutSearchItem itemWithTitle:@"Find my observations"
                                                              action:^{
                                                                  if ([[NSUserDefaults standardUserDefaults] objectForKey:INatUsernamePrefKey]) {
                                                                      [self searchForMyObservations];
                                                                      [searchMenu showActiveSearch];
                                                                  } else {
                                                                      [[[UIAlertView alloc] initWithTitle:@"You must be logged in!"
                                                                                                  message:nil
                                                                                                 delegate:nil
                                                                                        cancelButtonTitle:@"OK"
                                                                                        otherButtonTitles:nil] show];
                                                                  }
                                                              }];
        view.shortcutItems = @[nearMe, mine];
        
        view.activeSearchFilterView.userInteractionEnabled = NO;
        [view.activeSearchFilterView.removeActiveSearchButton addTarget:self
                                                                 action:@selector(removeSearchPressed)
                                                       forControlEvents:UIControlEventTouchUpInside];
        view.activeSearchTextDelegate = self;
        
        view;
    });
    [self.view addSubview:searchMenu];
    
    // the search view overlays on top of all of the stuff in the container view
    self.overlayView = searchMenu;
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // set up the map|grid|list selector
    mapVC = [[ExploreMapViewController alloc] initWithNibName:nil bundle:nil];
    mapVC.observationDataSource = observationsController;
    gridVC = [[ExploreGridViewController alloc] initWithNibName:nil bundle:nil];
    gridVC.observationDataSource = observationsController;
    listVC = [[ExploreListViewController alloc] initWithNibName:nil bundle:nil];
    listVC.observationDataSource = observationsController;
    self.viewControllers = @[mapVC, gridVC, listVC];
    
    // configure the segmented control
    [self.viewControllers bk_each:^(UIViewController *vc) {
        if ([vc conformsToProtocol:@protocol(ExploreViewControllerControlIcon)]) {
            [self.segmentedControl insertSegmentWithImage:[((id <ExploreViewControllerControlIcon>)vc) controlIcon]
                          atIndex:[self.viewControllers indexOfObject:vc]
                                                 animated:NO];
        }
    }];
    
    // display first item
    [self.segmentedControl setSelectedSegmentIndex:0];
    [self displayContentController:mapVC];
    
    NSDictionary *views = @{
                            @"searchMenu": searchMenu,
                            @"topLayoutGuide": self.topLayoutGuide,
                            @"bottomLayoutGuide": self.bottomLayoutGuide,
                            };
    
    
    // Configure the Active Search UI
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[searchMenu]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[topLayoutGuide]-0-[searchMenu]-0-[bottomLayoutGuide]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
}


#pragma mark - UIControl targets

- (void)refreshPressed {
    [observationsController reload];
}

- (void)removeSearchPressed {
    [searchMenu hideActiveSearch];
    
    [observationsController removeAllSearchPredicates];
}

- (void)searchPressed {
    if ([searchMenu optionSearchIsActive]) {
        if (observationsController.activeSearchPredicates.count > 0) {
            [searchMenu showActiveSearch]; // implicitly hides option search
        } else {
            [searchMenu hideOptionSearch];
        }
    } else {
        [searchMenu showOptionSearch];
    }
}

#pragma mark - iNat API Calls

- (void)searchForMyObservations {
    // clear all active search predicates
    // since it's not built to remove them one at a time yet
    [observationsController removeAllSearchPredicatesUpdatingObservations:NO];
    
    [SVProgressHUD showWithStatus:@"Fetching..." maskType:SVProgressHUDMaskTypeGradient];
    
    [searchController searchForLogin:[[NSUserDefaults standardUserDefaults] valueForKey:INatUsernamePrefKey] completionHandler:^(NSArray *results, NSError *error) {
        if (error) {
            
        } else {
            
            [[Analytics sharedClient] event:kAnalyticsEventExploreSearchMine];
            
            if (results.count == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD showErrorWithStatus:@"Can't find your user details. :("];
                });
            } else if (results.count == 1) {
                // dismiss the HUD
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD showSuccessWithStatus:@"Found you!"];
                });
                
                // observations controller will fetch observations using this predicate
                [observationsController addSearchPredicate:[ExploreSearchPredicate predicateForPerson:results.firstObject]];
                
                [searchMenu showActiveSearch];

            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD showErrorWithStatus:@"Found conflicting user details. :("];
                });
            }
        }
        
    }];
    
}

- (void)searchForNearbyObservations {
    hasFulfilledLocationFetch = NO;
    
    [[Analytics sharedClient] event:kAnalyticsEventExploreSearchNearMe];
    
    // clear all active search predicates
    // since it's not built to remove them one at a time yet
    [observationsController removeAllSearchPredicatesUpdatingObservations:NO];
    
    // no predicates, so hide the active search UI
    [searchMenu hideActiveSearch];
    
    // get observations near current location
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusNotDetermined:
            [self startLookingForCurrentLocation];
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [self startLookingForCurrentLocation];
            break;
            
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted:
            [[[UIAlertView alloc] initWithTitle:@"Permission denied"
                                        message:@"We don't have permission from iOS to use your location."
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        default:
            break;
    }
}

- (void)searchForTaxon:(NSString *)text {
    [SVProgressHUD showWithStatus:@"Searching for critters..." maskType:SVProgressHUDMaskTypeGradient];
    
    [searchController searchForTaxon:text completionHandler:^(NSArray *results, NSError *error) {
        if (error) {
            [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        } else {
            
            [[Analytics sharedClient] event:kAnalyticsEventExploreSearchCritters];

            if (results.count == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD showErrorWithStatus:@"No such critters found. :("];
                });
            } else if (results.count == 1) {
                // dismiss the HUD
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD showSuccessWithStatus:@"Found one!"];
                });
                
                // observations controller will fetch observations using this predicate
                [observationsController addSearchPredicate:[ExploreSearchPredicate predicateForTaxon:results.firstObject]];
                
                [searchMenu showActiveSearch];
                
            } else {
                
                // allow the user to disambiguate the search results
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD dismiss];
                });
                
                ExploreDisambiguator *disambiguator = [[ExploreDisambiguator alloc] init];
                disambiguator.title = @"Which critter?";
                disambiguator.searchOptions = results;
                
                __weak typeof(self)weakSelf = self;
                disambiguator.chosenBlock = ^void(id choice) {
                    // observations controller will fetch observations using this taxon
                    [observationsController addSearchPredicate:[ExploreSearchPredicate predicateForTaxon:(Taxon *)choice]];
                    
                    __strong typeof(weakSelf)strongSelf = weakSelf;
                    [strongSelf->searchMenu showActiveSearch];
                };
                [disambiguator presentDisambiguationAlert];
            }
        }
    }];
    
}

- (void)searchForPerson:(NSString *)text {
    
    [SVProgressHUD showWithStatus:@"Searching for people..." maskType:SVProgressHUDMaskTypeGradient];

    [searchController searchForPerson:text completionHandler:^(NSArray *results, NSError *error) {
        if (error) {
            [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        } else {
            
            [[Analytics sharedClient] event:kAnalyticsEventExploreSearchPeople];
            
            if (results.count == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD showErrorWithStatus:@"No such person found. :("];
                });
            } else if (results.count == 1) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD showSuccessWithStatus:@"Found one!"];
                });
                
                // observations controller will fetch observations using this predicate
                [observationsController addSearchPredicate:[ExploreSearchPredicate predicateForPerson:results.firstObject]];
                
                [searchMenu showActiveSearch];
                
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD dismiss];
                });
                
                ExploreDisambiguator *disambiguator = [[ExploreDisambiguator alloc] init];
                disambiguator.title = @"Which person?";
                disambiguator.searchOptions = results;
                
                __weak typeof(self)weakSelf = self;
                disambiguator.chosenBlock = ^void(id choice) {
                    __strong typeof(weakSelf)strongSelf = weakSelf;

                    // observations controller will fetch observations using this predicate
                    [strongSelf->observationsController addSearchPredicate:[ExploreSearchPredicate predicateForPerson:(ExplorePerson *)choice]];
                    
                    [strongSelf->searchMenu showActiveSearch];
                };
                [disambiguator presentDisambiguationAlert];
            }
        }
    }];
}

- (void)searchForLocation:(NSString *)text {
    [SVProgressHUD showWithStatus:@"Searching for place..." maskType:SVProgressHUDMaskTypeGradient];
    
    [searchController searchForLocation:text completionHandler:^(NSArray *results, NSError *error) {
        if (error) {
            [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        } else {
            
            [[Analytics sharedClient] event:kAnalyticsEventExploreSearchPlaces];

            // filter out garbage locations
            NSArray *validPlaces = [results bk_select:^BOOL(ExploreLocation *location) {
                // all administrative places, except towns, are valid
                if (location.adminLevel && location.adminLevel.integerValue != 3) { return YES; }
                // all open spaces (parks) are valid
                if (location.type == 100) { return YES; }
                // everything else is invalid
                return NO;
            }];
            
            if (validPlaces.count == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD showErrorWithStatus:@"No such place found. :("];
                });
            } else if (validPlaces.count == 1) {
                // dismiss the HUD
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD showSuccessWithStatus:@"Found one!"];
                });
                
                // observations controller will fetch observations using this predicate
                [observationsController addSearchPredicate:[ExploreSearchPredicate predicateForLocation:(ExploreLocation *)validPlaces.firstObject]];
                
                [searchMenu showActiveSearch];
                
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD dismiss];
                });
                
                ExploreDisambiguator *disambiguator = [[ExploreDisambiguator alloc] init];
                disambiguator.title = @"Which place?";
                disambiguator.searchOptions = results;
                
                __weak typeof(self)weakSelf = self;
                disambiguator.chosenBlock = ^void(id choice) {
                    __strong typeof(weakSelf)strongSelf = weakSelf;

                    // observations controller will fetch observations using this predicate
                    [strongSelf->observationsController addSearchPredicate:[ExploreSearchPredicate predicateForLocation:(ExploreLocation *)choice]];

                    [strongSelf->searchMenu showActiveSearch];
                };
                [disambiguator presentDisambiguationAlert];
            }
        }
    }];
    
}

- (void)searchForProject:(NSString *)text {
    [SVProgressHUD showWithStatus:@"Searching for project..." maskType:SVProgressHUDMaskTypeGradient];
    
    [searchController searchForProject:text completionHandler:^(NSArray *results, NSError *error) {
        if (error) {
            [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        } else {
            [[Analytics sharedClient] event:kAnalyticsEventExploreSearchProjects];
            
            if (results.count == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD showErrorWithStatus:@"No such project found."];
                });
            } else if (results.count == 1) {
                // dismiss the HUD
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD showSuccessWithStatus:@"Found one!"];
                });
                
                // observations controller will fetch observations using this predicate
                [observationsController addSearchPredicate:[ExploreSearchPredicate predicateForProject:results.firstObject]];
                
                [searchMenu showActiveSearch];

            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD dismiss];
                });
                
                ExploreDisambiguator *disambiguator = [[ExploreDisambiguator alloc] init];
                disambiguator.title = @"Which project?";
                disambiguator.searchOptions = results;
                
                __weak typeof(self)weakSelf = self;
                disambiguator.chosenBlock = ^void(id choice) {
                    __strong typeof(weakSelf)strongSelf = weakSelf;

                    // observations controller will fetch observations using this predicate
                    [strongSelf->observationsController addSearchPredicate:[ExploreSearchPredicate predicateForProject:(ExploreProject *)choice]];

                    [strongSelf->searchMenu showActiveSearch];
                };
                [disambiguator presentDisambiguationAlert];
            }
        }
    }];    
}


#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    isFetchingLocation = NO;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if (hasFulfilledLocationFetch)
        return;
    
    isFetchingLocation = NO;
    CLLocation *recentLocation = locations.lastObject;
    
    [locationFetchTimer invalidate];
    
    [locationManager stopUpdatingLocation];
    
    // one location fetch per user interaction with the "find observations near me" menu item
    if (!hasFulfilledLocationFetch) {
        hasFulfilledLocationFetch = YES;
        [SVProgressHUD showSuccessWithStatus:@"Found you!"];
        
        [mapVC mapShouldZoomToCoordinates:recentLocation.coordinate andShowUserLocation:YES];
    }
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (hasFulfilledLocationFetch)
        return;
    
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusNotDetermined:
            return;
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [self startLookingForCurrentLocation];
            break;
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted:
            [[[UIAlertView alloc] initWithTitle:@"Permission denied"
                                        message:@"We don't have permission from iOS to use your location."
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        default:
            break;
    }
}

#pragma mark - Location Manager helpers

- (void)startLookingForCurrentLocation {
    if (isFetchingLocation)
        return;
    
    if (hasFulfilledLocationFetch)
        return;
    
    isFetchingLocation = YES;
    locationManager = [[CLLocationManager alloc] init];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        // request will start over
        [locationManager requestWhenInUseAuthorization];
    }
    
    locationManager.delegate = self;
    locationManager.distanceFilter = 1000;
    [locationManager stopUpdatingLocation];
    [locationManager startUpdatingLocation];
    // this may take a moment
    [SVProgressHUD showWithStatus:@"Finding your location..."
                         maskType:SVProgressHUDMaskTypeGradient];
    locationFetchTimer = [NSTimer bk_scheduledTimerWithTimeInterval:15.0f
                                                              block:^(NSTimer *timer) {
                                                                  [SVProgressHUD showErrorWithStatus:@"Unable to find location"];
                                                                  [locationManager stopUpdatingLocation];
                                                                  locationManager = nil;
                                                                  isFetchingLocation = NO;
                                                              }
                                                            repeats:NO];
}



#pragma mark ActiveSearchText delegate

- (NSString *)activeSearchText {
    return observationsController.combinedColloquialSearchPhrase;
}

@end
