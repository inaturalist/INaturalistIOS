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
#import <RestKit/RestKit.h>
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

#define SEARCH_AUTOCOMPLETE_CELL @"SearchAutocompleteCell"
#define SEARCH_SHORTCUT_CELL @"SearchShortcutCell"

@interface ExploreSearchViewController () <UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate, CLLocationManagerDelegate> {
    ExploreObservationsController *observationsController;
    
    UIView *searchView;
    UISearchBar *searchBar;
    UITableView *searchResultsTableView;
    
    ExploreActiveSearchView *activeSearchFilterView;
    
    NSLayoutConstraint *searchResultsTableViewHeightConstraint;
    
    
    CLLocationManager *locationManager;
    
    NSTimer *locationFetchTimer;
    BOOL hasFulfilledLocationFetch;
    BOOL isFetchingLocation;

    // for geocoding place search text
    CLGeocoder *geocoder;
    UIAlertView *geocoderHelperAlertView;
    NSArray *geocodedPlaces;
    
    // for choosing among project search
    UIAlertView *projectSearchHelperAlertView;
    UITableView *projectSearchHelperTableView;
    NSArray *searchedProjects;
    
    UIAlertView *placeSearchHelperAlertView;
    UITableView *placeSearchHelperTableView;
    NSArray *searchedPlaces;
    
    UIAlertView *peopleSearchHelperAlertView;
    UITableView *peopleSearchHelperTableView;
    NSArray *searchedPeople;
    
    UIAlertView *taxaSearchHelperAlertView;
    UITableView *taxaSearchHelperTableView;
    NSArray *searchedTaxa;
    
    ExploreMapViewController *mapVC;
    ExploreGridViewController *gridVC;
    ExploreListViewController *listVC;
}

@end


@implementation ExploreSearchViewController

// since we're coming out of a storyboard, -initWithCoder: is the initializer
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        
        FAKIcon *worldOutline = [FAKIonIcons ios7WorldOutlineIconWithSize:35];;
        FAKIcon *worldFilled = [FAKIonIcons ios7WorldIconWithSize:35];
        
        [worldOutline addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
        [worldFilled addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
        
        self.navigationController.tabBarItem.image = [worldOutline imageWithSize:CGSizeMake(34, 45)];
        self.navigationController.tabBarItem.selectedImage = [worldFilled imageWithSize:CGSizeMake(34, 45)];
        
        self.navigationController.tabBarItem.title = @"Explore";
        
        observationsController = [[ExploreObservationsController alloc] init];
        
        geocoder = [[CLGeocoder alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // tab bar ui
    self.tabBarItem.title = @"Container";
    
    // nav bar ui
    UIBarButtonItem *search = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                                                            target:self
                                                                            action:@selector(searchPressed)];
    self.navigationItem.leftBarButtonItem = search;
    
    UIBarButtonItem *refresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                             target:self
                                                                             action:@selector(refreshPressed)];
    self.navigationItem.rightBarButtonItem = refresh;
    
    // set up the search ui
    searchView = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        
        view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
        view.hidden = YES;
        
        searchBar = ({
            UISearchBar *bar = [[UISearchBar alloc] initWithFrame:CGRectZero];
            bar.translatesAutoresizingMaskIntoConstraints = NO;
            
            bar.delegate = self;
            bar.placeholder = @"Search";        // follow Apple mail example
            
            bar;
        });
        [view addSubview:searchBar];
        
        searchResultsTableView = ({
            UITableView *tv = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
            tv.translatesAutoresizingMaskIntoConstraints = NO;
            
            tv.dataSource = self;
            
            tv.delegate = self;
            [tv registerClass:[ExploreSearchCompleteCell class] forCellReuseIdentifier:SEARCH_AUTOCOMPLETE_CELL];
            [tv registerClass:[UITableViewCell class] forCellReuseIdentifier:SEARCH_SHORTCUT_CELL];
            
            tv;
        });
        [view addSubview:searchResultsTableView];
        
        view;
    });
    [self.view addSubview:searchView];
    
    // the search view overlays on top of all of the stuff in the container view
    self.overlayView = searchView;
    
    activeSearchFilterView = ({
        ExploreActiveSearchView *view = [[ExploreActiveSearchView alloc] initWithFrame:CGRectZero];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        
        view.userInteractionEnabled = NO;
        
        [view.removeActiveSearchButton addTarget:self
                                          action:@selector(removeSearchPressed)
                                forControlEvents:UIControlEventTouchUpInside];
        
        view.hidden = YES;
        
        view;
    });
    [self.view insertSubview:activeSearchFilterView aboveSubview:searchView];
    
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
                            @"searchView": searchView,
                            @"topLayoutGuide": self.topLayoutGuide,
                            @"bottomLayoutGuide": self.bottomLayoutGuide,
                            @"searchBar": searchBar,
                            @"searchResultsTableView": searchResultsTableView,
                            @"activeSearchFilterView": activeSearchFilterView,
                            };
    
    
    // Configure the Active Search UI
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[activeSearchFilterView]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[topLayoutGuide]-0-[activeSearchFilterView]-0-[bottomLayoutGuide]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    
    
    
    
    // Configure the Search UI
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[searchView]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[searchView]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[searchBar]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[searchResultsTableView]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[topLayoutGuide]-0-[searchBar]-0-[searchResultsTableView]"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    
    searchResultsTableViewHeightConstraint = [NSLayoutConstraint constraintWithItem:searchResultsTableView
                                                                          attribute:NSLayoutAttributeHeight
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:nil
                                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                                         multiplier:1.0f
                                                                           constant:0.0f];
    [self.view addConstraint:searchResultsTableViewHeightConstraint];
}


#pragma mark - UIControl targets

- (void)refreshPressed {
    [observationsController reload];
}

- (void)removeSearchPressed {
    activeSearchFilterView.activeSearchLabel.text = @"";
    activeSearchFilterView.hidden = YES;
    
    [observationsController removeAllSearchPredicates];
}

- (void)searchPressed {
    if (searchView.hidden) {
        searchView.hidden = NO;
        searchResultsTableViewHeightConstraint.constant = [self heightForTableView:searchResultsTableView
                                                                     withRowHeight:44.0f];
        [self.view layoutIfNeeded];
        activeSearchFilterView.hidden = YES;
    } else {
        [searchBar resignFirstResponder];
        searchView.hidden = YES;
        if (observationsController.activeSearchPredicates.count > 0) {
            activeSearchFilterView.hidden = NO;
        }
    }
}

#pragma mark - iNat API Calls

- (void)searchForMyObservations {
    
    // clear all active search predicates
    // since it's not built to remove them one at a time yet
    [observationsController removeAllSearchPredicatesUpdatingObservations:NO];
    
    [SVProgressHUD showWithStatus:@"Fetching..." maskType:SVProgressHUDMaskTypeGradient];
    
    RKObjectMapping *mapping = [ExploreMappingProvider personMapping];
    
    NSString *pathPattern = [NSString stringWithFormat:@"/people/%@.json", [[NSUserDefaults standardUserDefaults] valueForKey:INatUsernamePrefKey]];
    NSString *query = @"?per_page=1";
    NSString *path = [NSString stringWithFormat:@"%@%@", pathPattern, query];
    RKObjectLoader *objectLoader = [[RKObjectManager sharedManager] objectLoaderWithResourcePath:path delegate:nil];
    objectLoader.method = RKRequestMethodGET;
    objectLoader.objectMapping = mapping;
    
    objectLoader.onDidLoadObjects = ^(NSArray *array) {
        NSArray *results = [array copy];
        
        [[Analytics sharedClient] event:kAnalyticsEventExploreSearchPeople];
        
        if (results.count == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:@"Can't find your user details. :("];
            });
        } else if (results.count == 1) {
            // dismiss the HUD
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showSuccessWithStatus:@"Found you!"];
            });
            
            // configure the predicate for the place that was found
            ExploreSearchPredicate *predicate = [[ExploreSearchPredicate alloc] init];
            predicate.type = ExploreSearchPredicateTypePeople;
            predicate.searchPerson = results.firstObject;
            
            // observations controller will fetch observations using this predicate
            [observationsController addSearchPredicate:predicate];
            
            // configure and show the "active search" UI
            activeSearchFilterView.activeSearchLabel.text = observationsController.combinedColloquialSearchPhrase;
            activeSearchFilterView.hidden = NO;
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:@"Found conflicting user details. :("];
            });
        }
    };
    
    objectLoader.onDidFailWithError = ^(NSError *err) {
        [SVProgressHUD showErrorWithStatus:err.localizedDescription];
    };
    
    objectLoader.onDidFailLoadWithError = ^(NSError *err) {
        [SVProgressHUD showErrorWithStatus:err.localizedDescription];
    };
    
    [objectLoader send];
}

- (void)searchForNearbyObservations {
    hasFulfilledLocationFetch = NO;
    
    [[Analytics sharedClient] event:kAnalyticsEventExploreSearchNearMe];
    
    // clear all active search predicates
    // since it's not built to remove them one at a time yet
    [observationsController removeAllSearchPredicatesUpdatingObservations:NO];
    
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
    
    RKObjectMapping *mapping = [Taxon mapping];
    
    NSString *pathPattern = @"/taxa/search.json";
    NSString *queryBase = @"?per_page=20&q=%@";
    NSString *query = [NSString stringWithFormat:queryBase, text];
    
    NSString *path = [NSString stringWithFormat:@"%@%@", pathPattern, query];
    RKObjectLoader *objectLoader = [[RKObjectManager sharedManager] objectLoaderWithResourcePath:path delegate:nil];
    objectLoader.method = RKRequestMethodGET;
    objectLoader.objectMapping = mapping;
    
    objectLoader.onDidLoadObjects = ^(NSArray *array) {
        NSArray *results = [array copy];
        
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
            
            // configure the predicate for the place that was found
            ExploreSearchPredicate *predicate = [[ExploreSearchPredicate alloc] init];
            predicate.type = ExploreSearchPredicateTypeCritter;
            predicate.searchTaxon = results.firstObject;
            
            // observations controller will fetch observations using this predicate
            [observationsController addSearchPredicate:predicate];
            
            // configure and show the "active search" UI
            activeSearchFilterView.activeSearchLabel.text = observationsController.combinedColloquialSearchPhrase;
            activeSearchFilterView.hidden = NO;
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
            });
            
            ExploreDisambiguator *disambiguator = [[ExploreDisambiguator alloc] init];
            disambiguator.title = @"Which critter?";
            disambiguator.searchOptions = results;
            
            __weak typeof(self)weakSelf = self;
            disambiguator.chosenBlock = ^void(id choice) {
                // get the taxon they chose
                Taxon *taxon = (Taxon *)choice;
                // fetch observations from this taxon from inat
                ExploreSearchPredicate *predicate = [[ExploreSearchPredicate alloc] init];
                predicate.type = ExploreSearchPredicateTypeCritter;
                predicate.searchTaxon = taxon;
                
                __strong typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf->observationsController addSearchPredicate:predicate];
                // configure and show the "active search" UI
                strongSelf->activeSearchFilterView.activeSearchLabel.text = strongSelf->observationsController.combinedColloquialSearchPhrase;
                strongSelf->activeSearchFilterView.hidden = NO;
            };
            [disambiguator presentDisambiguationAlert];
        }
    };
    
    objectLoader.onDidFailWithError = ^(NSError *err) {
        [SVProgressHUD showErrorWithStatus:err.localizedDescription];
    };
    
    objectLoader.onDidFailLoadWithError = ^(NSError *err) {
        [SVProgressHUD showErrorWithStatus:err.localizedDescription];
    };
    
    [objectLoader send];
}

- (void)searchForPeople:(NSString *)text {
    [SVProgressHUD showWithStatus:@"Searching for people..." maskType:SVProgressHUDMaskTypeGradient];
    
    RKObjectMapping *mapping = [ExploreMappingProvider personMapping];
    
    NSString *pathPattern = @"/people/search.json";
    NSString *queryBase = @"?per_page=50&q=%@";
    NSString *query = [NSString stringWithFormat:queryBase, text];
    
    NSString *path = [NSString stringWithFormat:@"%@%@", pathPattern, query];
    RKObjectLoader *objectLoader = [[RKObjectManager sharedManager] objectLoaderWithResourcePath:path delegate:nil];
    objectLoader.method = RKRequestMethodGET;
    objectLoader.objectMapping = mapping;
    
    objectLoader.onDidLoadObjects = ^(NSArray *array) {
        NSArray *results = [array copy];
        
        [[Analytics sharedClient] event:kAnalyticsEventExploreSearchPeople];
        
        if (results.count == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:@"No such people found. :("];
            });
        } else if (results.count == 1) {
            // dismiss the HUD
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showSuccessWithStatus:@"Found one!"];
            });
            
            // configure the predicate for the place that was found
            ExploreSearchPredicate *predicate = [[ExploreSearchPredicate alloc] init];
            predicate.type = ExploreSearchPredicateTypePeople;
            predicate.searchPerson = results.firstObject;
            
            // observations controller will fetch observations using this predicate
            [observationsController addSearchPredicate:predicate];
            
            // configure and show the "active search" UI
            activeSearchFilterView.activeSearchLabel.text = observationsController.combinedColloquialSearchPhrase;
            activeSearchFilterView.hidden = NO;
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
            });
            
            ExploreDisambiguator *disambiguator = [[ExploreDisambiguator alloc] init];
            disambiguator.title = @"Which person?";
            disambiguator.searchOptions = results;
            
            __weak typeof(self)weakSelf = self;
            disambiguator.chosenBlock = ^void(id choice) {
                // get the taxon they chose
                ExplorePerson *person = (ExplorePerson *)choice;
                // fetch observations from this taxon from inat
                ExploreSearchPredicate *predicate = [[ExploreSearchPredicate alloc] init];
                predicate.type = ExploreSearchPredicateTypePeople;
                predicate.searchPerson = person;
                
                __strong typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf->observationsController addSearchPredicate:predicate];
                // configure and show the "active search" UI
                strongSelf->activeSearchFilterView.activeSearchLabel.text = strongSelf->observationsController.combinedColloquialSearchPhrase;
                strongSelf->activeSearchFilterView.hidden = NO;
            };
            [disambiguator presentDisambiguationAlert];
        }
    };
    
    objectLoader.onDidFailWithError = ^(NSError *err) {
        [SVProgressHUD showErrorWithStatus:err.localizedDescription];
    };
    
    objectLoader.onDidFailLoadWithError = ^(NSError *err) {
        [SVProgressHUD showErrorWithStatus:err.localizedDescription];
    };
    
    [objectLoader send];
}

- (void)searchForPlace:(NSString *)text {
    [SVProgressHUD showWithStatus:@"Searching for place..." maskType:SVProgressHUDMaskTypeGradient];
    
    RKObjectMapping *mapping = [ExploreMappingProvider locationMapping];
    
    NSString *pathPattern = @"/places/search.json";
    NSString *queryBase = @"?q=%@";
    NSString *query = [NSString stringWithFormat:queryBase, text];
    
    NSString *path = [NSString stringWithFormat:@"%@%@", pathPattern, query];
    RKObjectLoader *objectLoader = [[RKObjectManager sharedManager] objectLoaderWithResourcePath:path delegate:nil];
    objectLoader.method = RKRequestMethodGET;
    objectLoader.objectMapping = mapping;
    
    objectLoader.onDidLoadObjects = ^(NSArray *array) {
        NSArray *results = [array copy];
        
        // filter out garbage locations
        NSArray *validPlaces = [results bk_select:^BOOL(ExploreLocation *location) {
            // all administrative places, except towns, are valid
            if (location.adminLevel && location.adminLevel.integerValue != 3) { return YES; }
            // all open spaces (parks) are valid
            if (location.type == 100) { return YES; }
            // everything else is invalid
            return NO;
        }];
        
        [[Analytics sharedClient] event:kAnalyticsEventExploreSearchPlaces];
        
        if (validPlaces.count == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:@"No such place found. :("];
            });
        } else if (validPlaces.count == 1) {
            // dismiss the HUD
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showSuccessWithStatus:@"Found one!"];
            });
            
            ExploreLocation *location = (ExploreLocation *)validPlaces.firstObject;
            
            // configure the predicate for the location that was found
            ExploreSearchPredicate *predicate = [[ExploreSearchPredicate alloc] init];
            predicate.type = ExploreSearchPredicateTypeLocation;
            predicate.searchLocation = location;
            
            // observations controller will fetch observations using this predicate
            [observationsController addSearchPredicate:predicate];
            
            // configure and show the "active search" UI
            activeSearchFilterView.activeSearchLabel.text = observationsController.combinedColloquialSearchPhrase;
            activeSearchFilterView.hidden = NO;
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
            });
            
            ExploreDisambiguator *disambiguator = [[ExploreDisambiguator alloc] init];
            disambiguator.title = @"Which place?";
            disambiguator.searchOptions = results;
            
            __weak typeof(self)weakSelf = self;
            disambiguator.chosenBlock = ^void(id choice) {
                // get the taxon they chose
                ExploreLocation *location = (ExploreLocation *)choice;
                // fetch observations from this taxon from inat
                ExploreSearchPredicate *predicate = [[ExploreSearchPredicate alloc] init];
                predicate.type = ExploreSearchPredicateTypeLocation;
                predicate.searchLocation = location;
                
                __strong typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf->observationsController addSearchPredicate:predicate];
                // configure and show the "active search" UI
                strongSelf->activeSearchFilterView.activeSearchLabel.text = strongSelf->observationsController.combinedColloquialSearchPhrase;
                strongSelf->activeSearchFilterView.hidden = NO;
            };
            [disambiguator presentDisambiguationAlert];
        }
    };
    
    objectLoader.onDidFailWithError = ^(NSError *err) {
        [SVProgressHUD showErrorWithStatus:err.localizedDescription];
    };
    
    objectLoader.onDidFailLoadWithError = ^(NSError *err) {
        [SVProgressHUD showErrorWithStatus:err.localizedDescription];
    };
    
    [objectLoader send];
}

- (void)searchForProject:(NSString *)text {
    [SVProgressHUD showWithStatus:@"Searching for project..." maskType:SVProgressHUDMaskTypeGradient];
    
    RKObjectMapping *mapping = [ExploreMappingProvider projectMapping];
    
    NSString *pathPattern = @"/projects/search.json";
    NSString *queryBase = @"?per_page=50&q=%@";        // place_type=County|Open+Space
    NSString *query = [NSString stringWithFormat:queryBase, text];
    
    NSString *path = [NSString stringWithFormat:@"%@%@", pathPattern, query];
    RKObjectLoader *objectLoader = [[RKObjectManager sharedManager] objectLoaderWithResourcePath:path delegate:nil];
    objectLoader.method = RKRequestMethodGET;
    objectLoader.objectMapping = mapping;
    
    objectLoader.onDidLoadObjects = ^(NSArray *array) {
        NSArray *results = [array copy];
        
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
            
            // configure the predicate for the project that was found
            ExploreSearchPredicate *predicate = [[ExploreSearchPredicate alloc] init];
            predicate.type = ExploreSearchPredicateTypeProject;
            predicate.searchProject = results.firstObject;
            
            // observations controller will fetch observations using this predicate
            [observationsController addSearchPredicate:predicate];
            
            // configure and show the "active search" UI
            activeSearchFilterView.activeSearchLabel.text = observationsController.combinedColloquialSearchPhrase;
            activeSearchFilterView.hidden = NO;
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
            });
            
            ExploreDisambiguator *disambiguator = [[ExploreDisambiguator alloc] init];
            disambiguator.title = @"Which project?";
            disambiguator.searchOptions = results;
            
            __weak typeof(self)weakSelf = self;
            disambiguator.chosenBlock = ^void(id choice) {
                // get the taxon they chose
                ExploreProject *project = (ExploreProject *)choice;
                // fetch observations from this taxon from inat
                ExploreSearchPredicate *predicate = [[ExploreSearchPredicate alloc] init];
                predicate.type = ExploreSearchPredicateTypeProject;
                predicate.searchProject = project;
                
                __strong typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf->observationsController addSearchPredicate:predicate];
                // configure and show the "active search" UI
                strongSelf->activeSearchFilterView.activeSearchLabel.text = strongSelf->observationsController.combinedColloquialSearchPhrase;
                strongSelf->activeSearchFilterView.hidden = NO;
            };
            [disambiguator presentDisambiguationAlert];
        }
    };
    
    objectLoader.onDidFailWithError = ^(NSError *err) {
        [SVProgressHUD showErrorWithStatus:err.localizedDescription];
    };
    
    objectLoader.onDidFailLoadWithError = ^(NSError *err) {
        [SVProgressHUD showErrorWithStatus:err.localizedDescription];
    };
    
    [objectLoader send];
}

- (void)searchForCoordinate:(CLLocationCoordinate2D)coord {
    RKObjectMapping *mapping = [ExploreMappingProvider locationMapping];
    
    NSString *pathPattern = @"/places.json";
    NSString *queryBase = @"?per_page=50&latitude=%f&longitude=%f";
    NSString *query = [NSString stringWithFormat:queryBase, coord.latitude, coord.longitude];
    
    NSString *path = [NSString stringWithFormat:@"%@%@", pathPattern, query];
    RKObjectLoader *objectLoader = [[RKObjectManager sharedManager] objectLoaderWithResourcePath:path delegate:nil];
    objectLoader.method = RKRequestMethodGET;
    objectLoader.objectMapping = mapping;
    
    objectLoader.onDidLoadObjects = ^(NSArray *array) {
        NSArray *results = [array copy];
        
        NSArray *openSpaces = [results bk_select:^BOOL(ExploreLocation *location) {
            return (location.type == 100);
        }];
        NSArray *counties = [results bk_select:^BOOL(ExploreLocation *location) {
            return (location.type == 9);
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // pick a location to use
            // prefer open spaces to counties
            ExploreLocation *location = openSpaces.count ? openSpaces.lastObject : (counties.count ? counties.lastObject : nil);
            
            // don't do any anything else if we can't get a location
            if (!location) {
                [[[UIAlertView alloc] initWithTitle:@"No iNat Location"
                                            message:@"No iNat Location Found"
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
            } else {
                ExploreSearchPredicate *predicate = [[ExploreSearchPredicate alloc] init];
                predicate.type = ExploreSearchPredicateTypeLocation;
                predicate.searchLocation = location;
                
                [observationsController addSearchPredicate:predicate];
                
                // configure and show the "active search" UI
                activeSearchFilterView.activeSearchLabel.text = observationsController.combinedColloquialSearchPhrase;
                activeSearchFilterView.hidden = NO;
            }
        });
    };
    
    objectLoader.onDidFailWithError = ^(NSError *err) {
        [SVProgressHUD showErrorWithStatus:err.localizedDescription];
    };
    
    objectLoader.onDidFailLoadWithError = ^(NSError *err) {
        [SVProgressHUD showErrorWithStatus:err.localizedDescription];
    };
    
    [objectLoader send];
}

#pragma mark - UITableView delegate/datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        // search auto-complete section: "find observers named alex" etc
        // only show when search text isn't empty
        if (searchBar.superview && ![searchBar.text isEqualToString:@""])
            return 4;
        else
            return 0;
    } else {
        // search shortcut section: "find observations near me" etc
        // only show when search text is empty
        if ([searchBar.text isEqualToString:@""]) {
            if ([[NSUserDefaults standardUserDefaults] valueForKey:INatUsernamePrefKey]) {
                // 1 row for "search near me"
                // 1 row for "search my observations"
                return 2;
            } else {
                // no "my observations"
                return 1;
            }
        } else {
            return 0;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // remove the keyboard
    [searchBar resignFirstResponder];
    
    if (indexPath.section == 1) {
        if (indexPath.item == 0) {
            [self searchForNearbyObservations];
        } else {
            [self searchForMyObservations];
        }
        
        
    } else {
        // shouldn't really be possible to select a row with no search text
        // but be defensive anyways
        if ([searchBar.text isEqualToString:@""])
            return;
        
        switch (indexPath.row) {
            case 0:
                [self searchForTaxon:searchBar.text];
                break;
            case 1:
                // people search must be logged in
                if (![[NSUserDefaults standardUserDefaults] valueForKey:INatTokenPrefKey]) {
                    [[[UIAlertView alloc] initWithTitle:@"You must be logged in"
                                                message:@"People search requires logging in!"
                                               delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil] show];
                    return;
                } else {
                    [self searchForPeople:searchBar.text];
                }
                break;
            case 2:
                [self searchForPlace:searchBar.text];
                break;
            case 3:
                [self searchForProject:searchBar.text];
                break;
            default:
                break;
        }
    }
    
    // reset and hide the search UI
    searchBar.text = @"";
    [searchResultsTableView reloadData];
    [searchView layoutIfNeeded];
    searchView.hidden = YES;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        // autocomplete cells
        
        ExploreSearchCompleteCell *cell = (ExploreSearchCompleteCell *)[tableView dequeueReusableCellWithIdentifier:SEARCH_AUTOCOMPLETE_CELL];
        cell.searchText = searchBar.text;

        switch (indexPath.row) {
            case 0:
                [cell setSearchPredicateType:ExploreSearchPredicateTypeCritter];
                break;
            case 1:
                [cell setSearchPredicateType:ExploreSearchPredicateTypePeople];
                break;
            case 2:
                [cell setSearchPredicateType:ExploreSearchPredicateTypeLocation];
                break;
            case 3:
                [cell setSearchPredicateType:ExploreSearchPredicateTypeProject];
                break;
            default:
                break;
        }
        return cell;
        
    } else {
        //shortcut cells
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SEARCH_SHORTCUT_CELL];
        cell.textLabel.font = [UIFont italicSystemFontOfSize:14.0f];
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"Find observations near me";
                break;
            case 1:
                cell.textLabel.text = @"Find my observations";
                break;
            default:
                cell.textLabel.text = nil;
                break;
        }
        return cell;
    }
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

#pragma mark - tableview constraint helpers

- (CGFloat)heightForTableView:(UITableView *)tableView withRowHeight:(CGFloat)rowHeight {
    int numberOfRows = 0;
    for (int section = 0; section < searchResultsTableView.numberOfSections; section++)
        for (int row = 0; row < [searchResultsTableView numberOfRowsInSection:section]; row++)
            numberOfRows++;
    return rowHeight * numberOfRows;
}

#pragma mark - UISearchBar delegate

- (void)searchBar:(UISearchBar *)field textDidChange:(NSString *)searchText {
    [searchResultsTableView reloadData];
    searchResultsTableViewHeightConstraint.constant = [self heightForTableView:searchResultsTableView
                                                                 withRowHeight:44.0f];
    [self.view layoutIfNeeded];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)field {
    // simulate tap on first row
    [searchResultsTableView.delegate tableView:searchResultsTableView
                       didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

@end
