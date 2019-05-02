//
//  ProjectsViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/12/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <RestKit/RestKit.h>

#import "ProjectsViewController.h"
#import "Project.h"
#import "ProjectUser.h"
#import "Analytics.h"
#import "TutorialSinglePageViewController.h"
#import "INaturalistAppDelegate.h"
#import "LoginController.h"
#import "UIImage+INaturalist.h"
#import "ProjectTableViewCell.h"
#import "UIColor+INaturalist.h"
#import "NSURL+INaturalist.h"
#import "ProjectDetailV2ViewController.h"
#import "OnboardingLoginViewController.h"
#import "INatReachability.h"
#import "ExploreUserRealm.h"
#import "ProjectsAPI.h"
#import "ExploreProject.h"
#import "ExploreProjectRealm.h"

typedef NS_ENUM(NSInteger, ProjectSelection) {
    ProjectSelectionMine = 0,
    ProjectSelectionFeatured,
    ProjectSelectionNearby
};

@interface ProjectsViewController () <RKObjectLoaderDelegate, RKRequestDelegate, UISearchResultsUpdating>
@property UISearchController *searchController;
@end

@implementation ProjectsViewController

#pragma mark fetch* methods are fetching from inaturalist.org

- (void)fetchMyProjects {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (![appDelegate.loginController isLoggedIn]) {
        return;
    }
    ExploreUserRealm *me = appDelegate.loginController.meUserLocal;
    
    __weak typeof(self) weakSelf = self;
    [[self projectsAPI] joinedProjectsUserId:me.userId handler:^(NSArray *results, NSInteger count, NSError *error) {
        RLMRealm *realm = [RLMRealm defaultRealm];
        for (ExploreProject *project in results) {
            ExploreProjectRealm *epr = [[ExploreProjectRealm alloc] initWithMantleModel:project];
            epr.joined = YES;
            [realm beginWriteTransaction];
            [realm addOrUpdateObject:epr];
            [realm commitWriteTransaction];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
        });
    }];
}

- (void)fetchFeaturedProjects {
    __weak typeof(self) weakSelf = self;
    [[self projectsAPI] featuredProjectsHandler:^(NSArray *results, NSInteger count, NSError *error) {
        RLMRealm *realm = [RLMRealm defaultRealm];
        for (ExploreProject *project in results) {
            ExploreProjectRealm *epr = [[ExploreProjectRealm alloc] initWithMantleModel:project];
            [realm beginWriteTransaction];
            [realm addOrUpdateObject:epr];
            [realm commitWriteTransaction];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
        });
    }];
}

- (void)fetchNearbyProjects {
    if (self.lastLocation) {
        __weak typeof(self)weakSelf = self;
        [[self projectsAPI] projectsNear:self.lastLocation.coordinate
                                  radius:50
                                 handler:^(NSArray *results, NSInteger count, NSError *error) {
                                     RLMRealm *realm = [RLMRealm defaultRealm];
                                     for (ExploreProject *project in results) {
                                         ExploreProjectRealm *epr = [[ExploreProjectRealm alloc] initWithMantleModel:project];
                                         [realm beginWriteTransaction];
                                         [realm addOrUpdateObject:epr];
                                         [realm commitWriteTransaction];
                                     }
                                     
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         [weakSelf.tableView reloadData];
                                     });
                                 }];
    }
}

#pragma mark our API for project operations

- (ProjectsAPI *)projectsAPI {
    static ProjectsAPI *_api = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _api = [[ProjectsAPI alloc] init];
    });
    return _api;
}

#pragma mark helper for signup

- (void)showSignupPrompt:(NSString *)reason {
    __weak typeof(self) weakSelf = self;
    
    [[Analytics sharedClient] event:kAnalyticsEventNavigateOnboardingScreenLogin
                     withProperties:@{ @"via": @"projects" }];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Onboarding" bundle:nil];
    OnboardingLoginViewController *login = [storyboard instantiateViewControllerWithIdentifier:@"onboarding-login"];
    login.skippable = NO;
    login.closeAction = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        // switch back to featured
        [strongSelf.projectSelectionControl setSelectedSegmentIndex:ProjectSelectionFeatured];
        [strongSelf dismissViewControllerAnimated:YES completion:nil];
    };
    [weakSelf presentViewController:login animated:YES completion:nil];
}


#pragma mark - View lifecycle

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"projectDetailSegue"]) {
        ProjectDetailV2ViewController *vc = [segue destinationViewController];
        vc.project = sender;
    }
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        
        self.title = NSLocalizedString(@"Projects", nil);
        
        self.tabBarItem.image = ({
            FAKIcon *briefcaseInactive = [FAKIonIcons iosBriefcaseIconWithSize:35];
            [briefcaseInactive addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor]];
            [[briefcaseInactive imageWithSize:CGSizeMake(34, 45)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        });
        
        self.tabBarItem.selectedImage = ({
            FAKIcon *briefcaseActive = [FAKIonIcons iosBriefcaseIconWithSize:35];
            [briefcaseActive addAttribute:NSForegroundColorAttributeName value:[UIColor inatTint]];
            [[briefcaseActive imageWithSize:CGSizeMake(34, 45)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        });
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            [self.locationManager requestWhenInUseAuthorization];
        }
        self.locationManager.delegate = self;
        self.locationManager.distanceFilter = 1000;
    }
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    
    self.searchController.hidesNavigationBarDuringPresentation = YES;
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleProminent;
    self.searchController.dimsBackgroundDuringPresentation = NO;

    self.tableView.tableHeaderView = self.searchController.searchBar;
    // don't show default tableview placeholder below content cells
    self.tableView.tableFooterView = [UIView new];
    
    self.definesPresentationContext = YES;
    
    // try to sync "featured" projects automatically
    if ([[INatReachability sharedClient] isNetworkReachable]) {
        [self fetchFeaturedProjects];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;

    [self.tableView deselectRowAtIndexPath:[self.tableView.indexPathsForSelectedRows objectAtIndex:0] animated:YES];
    self.navigationController.navigationBar.translucent = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    //[self syncFinished];
    if (self.locationManager) {
        [self.locationManager stopUpdatingLocation];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsKeyOldTutorialSeen] &&
        ![[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsKeyTutorialNeverAgain] &&
        ![[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsKeyTutorialSeenProjects]) {
        
        TutorialSinglePageViewController *vc = [[TutorialSinglePageViewController alloc] initWithNibName:nil bundle:nil];
        vc.tutorialImage = [UIImage imageNamed:@"tutorial_projects"];
        vc.tutorialTitle = NSLocalizedString(@"Projects are collections of observations with a common purpose", @"Title for projects tutorial screen");
        vc.tutorialSubtitleOne = NSLocalizedString(@"Join projects to select them when you record observations", @"Subtitle above image for projects tutorial screen");
        NSString *tutorialSubtitleTwoBase = NSLocalizedString(@"Visit %@ to create your own projects",
                                                              @"Subtitle below image for projects tutorial screen. The string is the URL for iNat (or partner site)");
        vc.tutorialSubtitleTwo = [NSString stringWithFormat:tutorialSubtitleTwoBase, [NSURL inat_baseURL]];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self presentViewController:vc animated:YES completion:nil];
        });
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDefaultsKeyTutorialSeenProjects];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    if (self.locationManager) {
        [self.locationManager startUpdatingLocation];
    }
    //[self loadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [[[RKClient sharedClient] requestQueue] cancelRequestsWithDelegate:self];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.searchController.isActive) {
        return [[self filteredProjects] count];
    } else {
        return [[self projectsForActiveSelection] count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ProjectCell";
    
    ProjectTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[ProjectTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    ExploreProjectRealm *epr = nil;
    if (self.searchController.isActive) {
        epr = [[self filteredProjects] objectAtIndex:indexPath.row];
    } else {
        epr = [[self projectsForActiveSelection] objectAtIndex:indexPath.row];
    }
    
    cell.titleLabel.text = epr.title;
    [cell.projectImage cancelImageDownloadTask];
    [cell.projectImage setImageWithURL:[epr iconUrl]
                      placeholderImage:[UIImage inat_defaultProjectImage]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ExploreProjectRealm *project = nil;
    if (self.searchController.isActive) {
        project = [[self filteredProjects] objectAtIndex:indexPath.row];
    } else {
        project = [[self projectsForActiveSelection] objectAtIndex:indexPath.row];
    }
    
    if (project) {
        [self performSegueWithIdentifier:@"projectDetailSegue" sender:project];
    }
}

- (UISegmentedControl *)projectSelectionControl {
    static UISegmentedControl *_control = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *items = @[@"Joined", @"Featured", @"Nearby"];
        _control = [[UISegmentedControl alloc] initWithItems:items];
        _control.translatesAutoresizingMaskIntoConstraints = NO;

        [_control addTarget:self
                     action:@selector(projectSelectionChanged:)
           forControlEvents:UIControlEventValueChanged];
        _control.selectedSegmentIndex = 1;
    });
    
    return _control;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (self.searchController.isActive) {
        return [self viewForHeaderWithActiveSearch];
    } else {
        return [self viewForHeaderWithoutActiveSearch];
    }
}

- (UIView *)viewForHeaderWithActiveSearch {
    return [UIView new];
}

- (UIView *)viewForHeaderWithoutActiveSearch {
    static UIView *_header = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _header = [UIView new];
        [_header addSubview:self.projectSelectionControl];
        [[self projectSelectionControl].centerXAnchor constraintEqualToAnchor:_header.centerXAnchor].active = YES;
        [[self projectSelectionControl].centerYAnchor constraintEqualToAnchor:_header.centerYAnchor].active = YES;
    });
    
    return _header;
}


- (void)projectSelectionChanged:(UISegmentedControl *)control {
    if (control.selectedSegmentIndex == ProjectSelectionMine) {
        [self fetchMyProjects];
    } else if (control.selectedSegmentIndex == ProjectSelectionFeatured) {
        [self fetchFeaturedProjects];
    } else {
        [self fetchNearbyProjects];
    }
    
    [self.tableView reloadData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.searchController.isActive) {
        return 0;
    } else {
        return 44;
    }
}
 
#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
    // flag if we should sync location-based projects
    BOOL shouldSync = NO;
    
    if (!self.lastLocation) {
        // sync if we just rebooted the app
        shouldSync = YES;
    }
    self.lastLocation = newLocation;
    
    NSTimeInterval timeDelta = [newLocation.timestamp timeIntervalSinceDate:oldLocation.timestamp];
    if (timeDelta > 300) {
        // sync if last location update was more than 5 minutes ago
        shouldSync = YES;
    }
    
    CLLocationDistance distanceDelta = [newLocation distanceFromLocation:oldLocation];
    if (distanceDelta > 1609) {
        // sync if last location update was more than a mile ago
        shouldSync = YES;
    }
    
    if (shouldSync && [[INatReachability sharedClient] isNetworkReachable]) {
        //[self syncFeaturedProjects];
        //[self syncNearbyProjects];
    }
}

#pragma mark - RKRequest and RKObjectLoader delegates

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects {
    NSDate *now = [NSDate date];
    for (INatModel *o in objects) {
        [o setSyncedAt:now];
    }
    
    if ([objectLoader.URL.absoluteString rangeOfString:@"featured"].location != NSNotFound) {
        NSArray *rejects = [Project objectsWithPredicate:
                            [NSPredicate predicateWithFormat:@"featuredAt != nil && syncedAt < %@", now]];
        for (Project *p in rejects) {
            if (p.projectUsers.count == 0) {
                [p deleteEntity];
            } else {
                p.featuredAt = nil;
                p.syncedAt = now;
            }
        }
    } else if ([objectLoader.URL.path rangeOfString:@"projects/user"].location != NSNotFound) {
        NSArray *rejects = [ProjectUser objectsWithPredicate:[NSPredicate predicateWithFormat:@"syncedAt < %@", now]];
        for (ProjectUser *pu in rejects) {
            [pu deleteEntity];
        }
    }
    
    NSError *error = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
    if (error) {
        NSString *logMsg = [NSString stringWithFormat:@"SAVE ERROR: %@", error.localizedDescription];
        [[Analytics sharedClient] debugLog:logMsg];
    }
    
    //[self syncFinished];
    //[self loadData];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    //[self syncFinished];
    
    // KLUDGE!! RestKit doesn't seem to handle failed auth very well
    BOOL jsonParsingError = [error.domain isEqualToString:@"JKErrorDomain"] && error.code == -1;
    BOOL authFailure = [error.domain isEqualToString:@"NSURLErrorDomain"] && error.code == -1012;
    NSString *errorMsg = error.localizedDescription;
    
    if (jsonParsingError || authFailure) {
        [self showSignupPrompt:nil];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Whoops!",nil)
                                                                       message:[NSString stringWithFormat:NSLocalizedString(@"Looks like there was an error: %@",nil), errorMsg]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response {
    bool authFailure = false;
    NSString *errorMsg;
    switch (response.statusCode) {
        case 401:
            // Unauthorized
            authFailure = true;
            break;
        case 422:
            // UNPROCESSABLE ENTITY
            
            errorMsg = NSLocalizedString(@"Unprocessable entity",nil);
            break;
        default:
            return;
            break;
    }
    
    if (authFailure) {
        //[self syncFinished];
        [self showSignupPrompt:nil];
    } else if (errorMsg) {
        //[self syncFinished];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Whoops!",nil)
                                                                       message:[NSString stringWithFormat:NSLocalizedString(@"Looks like there was an error: %@",nil), errorMsg]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    if (searchController.searchBar.text.length > 0) {
        __weak typeof(self)weakSelf = self;
        [[self projectsAPI] searchProjectsTitleText:searchController.searchBar.text
                                            handler:^(NSArray *results, NSInteger count, NSError *error) {
                                                RLMRealm *realm = [RLMRealm defaultRealm];
                                                for (ExploreProject *project in results) {
                                                    ExploreProjectRealm *epr = [[ExploreProjectRealm alloc] initWithMantleModel:project];
                                                    [realm beginWriteTransaction];
                                                    [realm addOrUpdateObject:epr];
                                                    [realm commitWriteTransaction];
                                                }
                                                
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    [weakSelf.tableView reloadData];
                                                });
                                            }];
    }
    
    [self.tableView reloadData];
}

- (RLMResults *)filteredProjects {
    return [ExploreProjectRealm objectsWhere:@"title CONTAINS[c] %@",
            self.searchController.searchBar.text];
}

- (RLMResults *)projectsForSelection:(ProjectSelection)idx {
    if (idx == ProjectSelectionMine) {
        return self.myProjects;
    } else if (idx == ProjectSelectionNearby) {
        return self.nearbyProjects;
    } else {
        return self.featuredProjects;
    }
}

- (RLMResults *)projectsForActiveSelection {
    return [self projectsForSelection:[[self projectSelectionControl] selectedSegmentIndex]];
}

- (RLMResults *)featuredProjects {
    NSInteger siteId = 1;
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.loginController.meUserLocal) {
        siteId = appDelegate.loginController.meUserLocal.siteId;
    }
    return [ExploreProjectRealm featuredProjectsForSite:siteId];
}

- (RLMResults *)nearbyProjects {
    if (self.lastLocation) {
        return [ExploreProjectRealm projectsNear:self.lastLocation];
    } else {
        // TODO: show cannot determine location? or just hide nearby tab?
        return [ExploreProjectRealm projectsWithLocations];
    }
}

- (RLMResults *)myProjects {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.loginController.isLoggedIn) {
        return [ExploreProjectRealm joinedProjects];
    } else {
        // TODO: show empty list? or show not logged in? or just hide "my projects" tab?
        return @[];
    }
}

@end
