//
//  ExploreContainerViewController.m
//  Explore Prototype
//
//  Created by Alex Shepard on 9/12/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKFoundationIcons.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <BlocksKit/BlocksKit.h>
#import <RestKit/RestKit.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import "ExploreContainerViewController.h"

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

#define SEARCH_RESULTS_CELL_ID @"SearchResultsCell"

@interface ExploreContainerViewController () <UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate, CLLocationManagerDelegate> {
    ExploreObservationsController *observationsController;
    
    UIView *searchView;
    UISearchBar *searchBar;
    UITableView *searchResultsTableView;
    
    ExploreActiveSearchView *activeSearchFilterView;
    
    NSLayoutConstraint *searchResultsTableViewHeightConstraint;
    
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
    
    CLLocationManager *locationManager;
    
    NSTimer *locationFetchTimer;
    BOOL hasFulfilledLocationFetch;
    BOOL isFetchingLocation;
}
@end

static UIImage *userIconPlaceholder;

@implementation ExploreContainerViewController

// since we're coming out of a storyboard, -initWithCoder: is the initializer
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        
        FAKIcon *person = [FAKIonIcons ios7PersonIconWithSize:30.0f];
        [person addAttribute:NSForegroundColorAttributeName value:[UIColor inatBlack]];
        userIconPlaceholder = [person imageWithSize:CGSizeMake(30.0f, 30.0f)];
        
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
            [tv registerClass:[ExploreSearchCompleteCell class] forCellReuseIdentifier:SEARCH_RESULTS_CELL_ID];
            [tv registerClass:[UITableViewCell class] forCellReuseIdentifier:@"BlankSearchCell"];
            
            tv;
        });
        [view addSubview:searchResultsTableView];
        
        view;
    });
    [self.view addSubview:searchView];
    
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

    // set up the map|grid|list selector
    mapVC = [[ExploreMapViewController alloc] initWithNibName:nil bundle:nil];
    mapVC.observationDataSource = observationsController;
    gridVC = [[ExploreGridViewController alloc] initWithNibName:nil bundle:nil];
    gridVC.observationDataSource = observationsController;
    listVC = [[ExploreListViewController alloc] initWithNibName:nil bundle:nil];
    listVC.observationDataSource = observationsController;
    self.viewControllers = @[mapVC, gridVC, listVC];
    self.navigationItem.titleView = ({
        
        NSArray *images = [self.viewControllers bk_map:^id(UIViewController *vc) {
            if ([vc conformsToProtocol:@protocol(ExploreViewControllerControlIcon)]) {
                return [((id <ExploreViewControllerControlIcon>)vc) controlIcon];
            } else {
                return nil;
            }
        }];
        
        UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:images];
        [segmentedControl addTarget:self
                             action:@selector(segmentedControlChanged:)
                   forControlEvents:UIControlEventValueChanged];
        segmentedControl.selectedSegmentIndex = 0;
        
        segmentedControl.tintColor = [UIColor inatGreen];
        
        segmentedControl;
    });
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
    
    // fetch default observations
    [observationsController reload];
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
        searchResultsTableViewHeightConstraint.constant = (searchBar.text.length > 0) ? 220.0f : 44.0f;
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
            
            // show the user a list of taxa
            searchedTaxa = results;
            
            taxaSearchHelperAlertView = [[UIAlertView alloc] initWithTitle:@"Which critter?"
                                                                     message:nil
                                                                    delegate:self
                                                           cancelButtonTitle:@"Cancel"
                                                           otherButtonTitles:nil];
            CGRect taxaSearchTableViewRect = CGRectMake(0, 0, 275.0f, 180.0f);
            taxaSearchHelperTableView = [[UITableView alloc] initWithFrame:taxaSearchTableViewRect
                                                                     style:UITableViewStylePlain];
            [taxaSearchHelperTableView registerClass:[ExploreSearchResultsCell class] forCellReuseIdentifier:@"geocoder"];
            taxaSearchHelperTableView.delegate = self;
            taxaSearchHelperTableView.dataSource = self;
            [taxaSearchHelperAlertView setValue:taxaSearchHelperTableView
                                         forKey:@"accessoryView"];
            [taxaSearchHelperAlertView show];
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
            
            // show the user a list of people
            searchedPeople = results;
            
            peopleSearchHelperAlertView = [[UIAlertView alloc] initWithTitle:@"Which person?"
                                                                     message:nil
                                                                    delegate:self
                                                           cancelButtonTitle:@"Cancel"
                                                           otherButtonTitles:nil];
            CGRect peopleSearchTableViewRect = CGRectMake(0, 0, 275.0f, 180.0f);
            peopleSearchHelperTableView = [[UITableView alloc] initWithFrame:peopleSearchTableViewRect
                                                                       style:UITableViewStylePlain];
            [peopleSearchHelperTableView registerClass:[ExploreSearchResultsCell class] forCellReuseIdentifier:@"geocoder"];
            peopleSearchHelperTableView.delegate = self;
            peopleSearchHelperTableView.dataSource = self;
            [peopleSearchHelperAlertView setValue:peopleSearchHelperTableView
                                           forKey:@"accessoryView"];
            [peopleSearchHelperAlertView show];
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

            // show the user a list of places
            searchedPlaces = validPlaces;
            
            placeSearchHelperAlertView = [[UIAlertView alloc] initWithTitle:@"Which place?"
                                                                    message:nil
                                                                   delegate:self
                                                          cancelButtonTitle:@"Cancel"
                                                          otherButtonTitles:nil];
            CGRect placeSearchTableViewRect = CGRectMake(0, 0, 275.0f, 180.0f);
            placeSearchHelperTableView = [[UITableView alloc] initWithFrame:placeSearchTableViewRect
                                                                      style:UITableViewStylePlain];
            [placeSearchHelperTableView registerClass:[ExploreSearchResultsCell class] forCellReuseIdentifier:@"geocoder"];
            placeSearchHelperTableView.delegate = self;
            placeSearchHelperTableView.dataSource = self;
            [placeSearchHelperAlertView setValue:placeSearchHelperTableView
                                          forKey:@"accessoryView"];
            [placeSearchHelperAlertView show];
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
            
            // show the user a list of projects
            searchedProjects = results;
            
            projectSearchHelperAlertView = [[UIAlertView alloc] initWithTitle:@"Which project?"
                                                                      message:nil
                                                                     delegate:self
                                                            cancelButtonTitle:@"Cancel"
                                                            otherButtonTitles:nil];
            CGRect projectSearchTableViewRect = CGRectMake(0, 0, 275.0f, 180.0f);
            projectSearchHelperTableView = [[UITableView alloc] initWithFrame:projectSearchTableViewRect
                                                                        style:UITableViewStylePlain];
            [projectSearchHelperTableView registerClass:[ExploreSearchResultsCell class] forCellReuseIdentifier:@"geocoder"];
            projectSearchHelperTableView.delegate = self;
            projectSearchHelperTableView.dataSource = self;
            [projectSearchHelperAlertView setValue:projectSearchHelperTableView forKey:@"accessoryView"];
            [projectSearchHelperAlertView show];
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
        /*
        [mapVC mapShouldShowLocation]
        // fetch iNat place for this location
        RKObjectMapping *mapping = [ExploreMappingProvider locationMapping];
        
        NSString *pathPattern = @"/places.json";
        NSString *queryBase = @"?per_page=50&latitude=%f&longitude=%f";        // place_type=County|Open+Space
        NSString *query = [NSString stringWithFormat:queryBase,
                           recentLocation.coordinate.latitude,
                           recentLocation.coordinate.longitude];
        
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
                
                // assign search predicate with the chosen location
                if (!location) {
                    [[[UIAlertView alloc] initWithTitle:@"No location found"
                                                message:@"Nope. :("
                                               delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil] show];
                    return;
                }
                
                // configure the predicate for the place that was found
                ExploreSearchPredicate *predicate = [[ExploreSearchPredicate alloc] init];
                predicate.type = ExploreSearchPredicateTypeLocation;
                predicate.searchLocation = location;
                
                // observations controller will fetch observations using this predicate
                [observationsController addSearchPredicate:predicate];
                
                // configure and show the "active search" UI
                activeSearchFilterView.activeSearchLabel.text = observationsController.combinedColloquialSearchPhrase;
                activeSearchFilterView.hidden = NO;
            });
        };
        
        objectLoader.onDidFailWithError = ^(NSError *err) {
            [SVProgressHUD showErrorWithStatus:err.localizedDescription];
        };
        
        objectLoader.onDidFailLoadWithError = ^(NSError *err) {
            [SVProgressHUD showErrorWithStatus:err.localizedDescription];
        };
        
        [objectLoader send];      
         */
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

#pragma mark - UITableView delegate/datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == searchResultsTableView) {
        return 2;
    } else if (tableView == projectSearchHelperTableView) {
        return 1;
    } else {
        // geocoder helper
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == searchResultsTableView) {
        if (section == 0) {
            if (searchBar.superview && ![searchBar.text isEqualToString:@""])
                return 4;
            else
                return 0;
        } else {
            // 1 section for "search near me"
            return 1;
        }
    } else if (tableView == projectSearchHelperTableView) {
        // searched projects helper
        return searchedProjects.count;
    } else if (tableView == peopleSearchHelperTableView) {
        // searched people helper
        return searchedPeople.count;
    } else if (tableView == placeSearchHelperTableView) {
        return searchedPlaces.count;
    } else if (tableView == taxaSearchHelperTableView) {
        return searchedTaxa.count;
    } else {
        return 0;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == searchResultsTableView) {
        [searchBar resignFirstResponder];

        if (indexPath.section == 1) {
            hasFulfilledLocationFetch = NO;
            
            [[Analytics sharedClient] event:kAnalyticsEventExploreSearchNearMe];

            // reset and hide the search UI
            searchBar.text = @"";
            [searchResultsTableView reloadData];
            [searchView layoutIfNeeded];
            searchView.hidden = YES;
            
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

        } else {
            if ([searchBar.text isEqualToString:@""])
                return;
            
            if (indexPath.row == 2) {
                [self searchForPlace:searchBar.text];
            } else if (indexPath.row == 3) {
                // search for project
                [self searchForProject:searchBar.text];
            } else if (indexPath.row == 1) {
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
            } else {
                [self searchForTaxon:searchBar.text];
            }
            
            // reset and hide the search UI
            searchBar.text = @"";
            [searchResultsTableView reloadData];
            [searchView layoutIfNeeded];
            searchView.hidden = YES;
            
            return;
        }
    } else if (tableView == projectSearchHelperTableView) {
        // searched projects helper
        // dismiss the helper alert
        [projectSearchHelperAlertView dismissWithClickedButtonIndex:0 animated:YES];
        // get the project they tapped
        ExploreProject *project = [searchedProjects objectAtIndex:indexPath.item];
        // fetch observations for this project from inat
        ExploreSearchPredicate *predicate = [[ExploreSearchPredicate alloc] init];
        predicate.type = ExploreSearchPredicateTypeProject;
        predicate.searchProject = project;
        [observationsController addSearchPredicate:predicate];
        // configure and show the "active search" UI
        activeSearchFilterView.activeSearchLabel.text = observationsController.combinedColloquialSearchPhrase;
        activeSearchFilterView.hidden = NO;
    } else if (tableView == peopleSearchHelperTableView) {
        // searched people helper
        // dismiss the alert
        [peopleSearchHelperAlertView dismissWithClickedButtonIndex:0 animated:YES];
        // get the person they tapped
        ExplorePerson *person = [searchedPeople objectAtIndex:indexPath.item];
        // fetch observations from this person from inat
        ExploreSearchPredicate *predicate = [[ExploreSearchPredicate alloc] init];
        predicate.type = ExploreSearchPredicateTypePeople;
        predicate.searchPerson = person;
        [observationsController addSearchPredicate:predicate];
        // configure and show the "active search" UI
        activeSearchFilterView.activeSearchLabel.text = observationsController.combinedColloquialSearchPhrase;
        activeSearchFilterView.hidden = NO;
    } else if (tableView == placeSearchHelperTableView) {
        // searched places helper
        // dismiss the alert
        [placeSearchHelperAlertView dismissWithClickedButtonIndex:0 animated:YES];
        // get the location they tapped
        ExploreLocation *location = [searchedPlaces objectAtIndex:indexPath.item];
        // fetch observations from this person from inat
        ExploreSearchPredicate *predicate = [[ExploreSearchPredicate alloc] init];
        predicate.type = ExploreSearchPredicateTypeLocation;
        predicate.searchLocation = location;
        [observationsController addSearchPredicate:predicate];
        // configure and show the "active search" UI
        activeSearchFilterView.activeSearchLabel.text = observationsController.combinedColloquialSearchPhrase;
        activeSearchFilterView.hidden = NO;
    } else if (tableView == taxaSearchHelperTableView) {
        // searched taxa helper
        // dismiss the alert
        [taxaSearchHelperAlertView dismissWithClickedButtonIndex:0 animated:YES];
        // get the place they tapped
        Taxon *taxon = [searchedTaxa objectAtIndex:indexPath.item];
        // fetch observations from this person from inat
        ExploreSearchPredicate *predicate = [[ExploreSearchPredicate alloc] init];
        predicate.type = ExploreSearchPredicateTypeCritter;
        predicate.searchTaxon = taxon;
        [observationsController addSearchPredicate:predicate];
        // configure and show the "active search" UI
        activeSearchFilterView.activeSearchLabel.text = observationsController.combinedColloquialSearchPhrase;
        activeSearchFilterView.hidden = NO;
    } else {
        return;
        /*
        // geocoder helper
        // dismiss the helper alert
        [geocoderHelperAlertView dismissWithClickedButtonIndex:0 animated:YES];
        // get the place they tapped
        CLPlacemark *place = [geocodedPlaces objectAtIndex:indexPath.item];
        // search iNat for it
        [self searchForCoordinate:place.location.coordinate];
         */
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == searchResultsTableView) {
        
        if (indexPath.section == 0) {
        
            ExploreSearchCompleteCell *cell = (ExploreSearchCompleteCell *)[tableView dequeueReusableCellWithIdentifier:SEARCH_RESULTS_CELL_ID];
            
            NSString *predicate;
            if (indexPath.item == 0) {
                [cell setSearchPredicateType:ExploreSearchPredicateTypeCritter];
                predicate = @"critters";
            } else if (indexPath.item == 1) {
                [cell setSearchPredicateType:ExploreSearchPredicateTypePeople];
                predicate = @"people";
            } else if (indexPath.item == 2) {
                [cell setSearchPredicateType:ExploreSearchPredicateTypeLocation];
                predicate = @"places";
            } else if (indexPath.item == 3) {
                [cell setSearchPredicateType:ExploreSearchPredicateTypeProject];
                predicate = @"projects";
            }
            cell.searchText = searchBar.text;
            
            return cell;
        } else {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BlankSearchCell"];
            cell.textLabel.text = @"Find observations near me";
            cell.textLabel.font = [UIFont italicSystemFontOfSize:14.0f];
            return cell;
        }
    } else if (tableView == projectSearchHelperTableView) {
        // project search helper
        ExploreSearchResultsCell *cell = (ExploreSearchResultsCell *)[tableView dequeueReusableCellWithIdentifier:@"geocoder"];
        ExploreProject *project = [searchedProjects objectAtIndex:indexPath.row];
        
        [cell.resultImageView sd_setImageWithURL:[NSURL URLWithString:project.iconUrl]
                                placeholderImage:[UIImage imageNamed:@"iconic_taxon_unknown.png"]];

        cell.resultTitle.text = project.title;
        cell.resultSubtitle.text = [NSString stringWithFormat:@"%ld observed taxa", (long)project.observedTaxaCount.integerValue];
        
        return cell;
    } else if (tableView == placeSearchHelperTableView) {
        // place search helper
        ExploreSearchResultsCell *cell = (ExploreSearchResultsCell *)[tableView dequeueReusableCellWithIdentifier:@"geocoder"];
        ExploreLocation *place = [searchedPlaces objectAtIndex:indexPath.row];
        
        cell.resultTitle.text = place.name;
        cell.resultSubtitle.text = place.placeTypeName;

        return cell;
    } else if (tableView == peopleSearchHelperTableView) {
        // people search helper
        ExploreSearchResultsCell *cell = (ExploreSearchResultsCell *)[tableView dequeueReusableCellWithIdentifier:@"geocoder"];
        ExplorePerson *person = [searchedPeople objectAtIndex:indexPath.row];
        
        if (person.name) {
            cell.resultTitle.text = person.name;
            cell.resultSubtitle.text = person.login;
        } else {
            cell.resultTitle.text = person.login;
        }
        
        // eg http://www.inaturalist.org/attachments/users/icons/44845-thumb.jpg
        NSString *observerAvatarUrlString = [NSString stringWithFormat:@"http://www.inaturalist.org/attachments/users/icons/%ld-thumb.jpg",
                                             (long)person.personId];
        [cell.resultImageView sd_setImageWithURL:[NSURL URLWithString:observerAvatarUrlString]
                                placeholderImage:userIconPlaceholder];
        
        return cell;
    } else if (tableView == taxaSearchHelperTableView) {
        // taxon search helper
        ExploreSearchResultsCell *cell = (ExploreSearchResultsCell *)[tableView dequeueReusableCellWithIdentifier:@"geocoder"];
        Taxon *taxon = [searchedTaxa objectAtIndex:indexPath.row];
        
        cell.resultTitle.text = taxon.defaultName;
        cell.resultTitle.textColor = [UIColor colorForIconicTaxon:taxon.iconicTaxonName];
        
        cell.resultSubtitle.font = [UIFont fontForTaxonRankName:taxon.rank ofSize:11.0f];
        if (taxon.isSpeciesOrLower)
            cell.resultSubtitle.text = taxon.name;
        else {
            NSMutableAttributedString *subtitle = [[NSMutableAttributedString alloc] init];
            NSMutableAttributedString *rank = [[NSMutableAttributedString alloc] initWithString:taxon.rank.capitalizedString
                                                                                     attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:11.0f] }];
            [subtitle appendAttributedString:rank];
            [subtitle appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];;
            NSMutableAttributedString *taxonName = [[NSMutableAttributedString alloc] initWithString:taxon.name
                                                                                          attributes:@{ NSFontAttributeName: [UIFont fontForTaxonRankName:taxon.rank ofSize:11.0f] }];
            [subtitle appendAttributedString:taxonName];
            cell.resultSubtitle.attributedText = subtitle;
        }
        
        TaxonPhoto *photo = [taxon.taxonPhotos firstObject];
        [cell.resultImageView sd_setImageWithURL:[NSURL URLWithString:photo.squareURL]
                                placeholderImage:[UIImage imageForIconicTaxon:taxon.iconicTaxonName]];
        
        return cell;
    } else {
        return nil;
    }
}

#pragma mark - UISearchBar delegate

- (void)searchBar:(UISearchBar *)field textDidChange:(NSString *)searchText {
    [searchResultsTableView reloadData];
    searchResultsTableViewHeightConstraint.constant = (searchText.length > 0) ? 220.0f : 44.0f;
    [self.view layoutIfNeeded];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)field {
    // simulate tap on first row
    [searchResultsTableView.delegate tableView:searchResultsTableView
                       didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

#pragma mark - Container Stuff
- (void)segmentedControlChanged:(UISegmentedControl *)control {
    // hide the old view controller
    [self hideContentController:self.selectedViewController];
    
    // show the selected view controller
    UIViewController *content = [self.viewControllers objectAtIndex:control.selectedSegmentIndex];
    [self displayContentController:content];
}

- (void)displayContentController:(UIViewController*)content {
    self.selectedViewController = content;
    [self addChildViewController:content];
    content.view.frame = [self frameForContentController];
    [self.view insertSubview:content.view
                belowSubview:searchView];
    [content didMoveToParentViewController:self];
}

- (void)hideContentController:(UIViewController*)content {
    [content willMoveToParentViewController:nil];
    [content.view removeFromSuperview];
    [content removeFromParentViewController];
}

- (CGRect)frameForContentController {
    return self.view.frame;
}


@end
