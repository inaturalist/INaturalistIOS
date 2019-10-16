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

static const int ListControlIndexFeatured = 1;
static const int ListControlIndexNearby = 2;

@interface ProjectsViewController () <RKObjectLoaderDelegate, RKRequestDelegate, UISearchResultsUpdating>
@property UISearchController *searchController;
@property NSArray *cachedProjects;
@property BOOL projectsFilterHasChanged;
@end

@implementation ProjectsViewController

#pragma mark - load* methods are loading locally from core data

- (NSArray *)projects {
    if (self.projectsFilterHasChanged) {
        self.cachedProjects = nil;
        self.projectsFilterHasChanged = FALSE;
    }
    
    if (self.cachedProjects) {
        return self.cachedProjects;
    }
    
    if (self.searchController.isActive && self.searchController.searchBar.text.length > 0) {
        // show searched projects
        self.cachedProjects = [self filteredProjects:self.searchController.searchBar.text];
    } else {
        // show projects for context
        switch (self.listControl.selectedSegmentIndex) {
            case ListControlIndexFeatured:
                self.cachedProjects = [self featuredProjects];
                break;
            case ListControlIndexNearby:
                self.cachedProjects = [self nearbyProjects];
                break;
            default:
                self.cachedProjects = [self userProjects];
                break;
        }
    }
    
    return self.cachedProjects;
}

- (NSArray *)titleSortDescriptors {
    return @[
        [NSSortDescriptor sortDescriptorWithKey:@"title"
                                      ascending:YES],
    ];
}

- (NSArray *)filteredProjects:(NSString *)searchTerm {
    NSArray *projects = [Project objectsWithPredicate:[NSPredicate predicateWithFormat:@"title contains[c] %@",
                                                       searchTerm]];
    return [projects sortedArrayUsingDescriptors:[self titleSortDescriptors]];
}

- (NSArray *)userProjects {
    NSArray *projectUsers = [ProjectUser.all sortedArrayUsingComparator:^NSComparisonResult(ProjectUser *obj1, ProjectUser *obj2) {
        return [obj1.project.title.lowercaseString compare:obj2.project.title.lowercaseString];
    }];
    // be defensive
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"project != nil"];
    return [[projectUsers filteredArrayUsingPredicate:predicate] valueForKey:@"project"];
}

- (NSArray *)featuredProjects {
    NSArray *projects = [Project objectsWithPredicate:[NSPredicate predicateWithFormat:@"featuredAt != nil"]];
    return [projects sortedArrayUsingDescriptors:[self titleSortDescriptors]];
}

- (NSArray *)nearbyProjects {
    // get all projects with a location
    NSFetchRequest *request = [Project fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"latitude != nil && longitude != nil"];
    request.fetchLimit = 500;
    NSArray *projectsWithLocations = [Project objectsWithFetchRequest:request];
    
    // anything less than 310 miles away is "nearby"
    NSPredicate *nearbyPredicate = [NSPredicate predicateWithBlock:^BOOL(Project *p, NSDictionary *bindings) {
        CLLocation *loc = [[CLLocation alloc] initWithLatitude:p.latitude.doubleValue
                                                     longitude:p.longitude.doubleValue];
        NSNumber *d = [NSNumber numberWithDouble:[self.lastLocation distanceFromLocation:loc]];
        return d.doubleValue < 500000; // meters
    }];
    NSArray *nearbyProjects = [projectsWithLocations filteredArrayUsingPredicate:nearbyPredicate];
    
    // sort nearby projects by how near they are (self.lastLocation)
    NSComparator nearnessComparator = ^NSComparisonResult(Project *p1, Project *p2) {
        CLLocation *p1Location = [[CLLocation alloc] initWithLatitude:p1.latitude.doubleValue
                                                            longitude:p1.longitude.doubleValue];
        CLLocation *p2Location = [[CLLocation alloc] initWithLatitude:p2.latitude.doubleValue
                                                            longitude:p2.longitude.doubleValue];
        NSNumber *p1Distance = [NSNumber numberWithDouble:[self.lastLocation distanceFromLocation:p1Location]];
        NSNumber *p2Distance = [NSNumber numberWithDouble:[self.lastLocation distanceFromLocation:p2Location]];
        return [p1Distance compare:p2Distance];
    };
    
    return [nearbyProjects sortedArrayUsingComparator:nearnessComparator];
}

#pragma mark - sync* methods are fetching from inaturalist.org

- (void)syncFeaturedProjects {
    NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSString *path = [NSString stringWithFormat:@"/projects.json?featured=true&locale=%@-%@",
                      language, countryCode];
    
    [self syncProjectsWithPath:path];
}

- (void)syncNearbyProjects {
    if (!self.lastLocation) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Couldn't determine your location",nil)
                                                                       message:NSLocalizedString(@"Make sure iNat has permission to access your location or give the GPS some time to fetch it.",nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        [self syncFinished];
        return;
    }
    NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
    NSString *language = [[NSLocale preferredLanguages] firstObject];
    NSString *path = [NSString stringWithFormat:@"/projects.json?latitude=%f&longitude=%f&locale=%@-%@",
                      self.lastLocation.coordinate.latitude,
                      self.lastLocation.coordinate.longitude,
                      language,
                      countryCode];
    
    [self syncProjectsWithPath:path];
}

- (void)syncUserProjects {
	INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
	if ([appDelegate.loginController isLoggedIn]) {
        ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
        NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
        NSString *language = [[NSLocale preferredLanguages] firstObject];
        NSString *path = [NSString stringWithFormat:@"/projects/user/%@.json?locale=%@-%@",
                          me.login,
                          language,
                          countryCode];
        
        [self syncProjectsWithPath:path];
    } else {
        [self syncFinished];

        [self showSignupPrompt:NSLocalizedString(@"You must be logged in to sync user projects.", @"Signup prompt reason when user tries to sync user projects.")];
    }
}

- (void)syncProjectsWithPath:(NSString *)path {
    
    RKObjectMapping *mapping = nil;
    if ([path rangeOfString:@"projects/user"].location != NSNotFound) {
        mapping = [ProjectUser mapping];
    } else {
        mapping = [Project mapping];
    }
    
    [[Analytics sharedClient] debugLog:@"Network - Load projects"];
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:path
                                                    usingBlock:^(RKObjectLoader *loader) {
                                                        loader.objectMapping = mapping;
                                                        loader.delegate = self;
                                                    }];
    
}

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
        [strongSelf.listControl setSelectedSegmentIndex:ListControlIndexFeatured];
        [strongSelf dismissViewControllerAnimated:YES completion:nil];
    };
    [weakSelf presentViewController:login animated:YES completion:nil];
}


- (void)syncFinished {
    self.navigationItem.rightBarButtonItem = self.searchButton;
}

- (UISegmentedControl *)listControl {
    if (!_listControl) {
        _listControl = [[UISegmentedControl alloc] initWithItems:@[
                                                                   NSLocalizedString(@"Joined",nil),
                                                                   NSLocalizedString(@"Featured",nil),
                                                                   NSLocalizedString(@"Nearby",nil)
                                                                   ]];
        _listControl.tintColor = [UIColor inatTint];
        
        NSString *inatToken = [[NSUserDefaults standardUserDefaults] objectForKey:INatTokenPrefKey];
        _listControl.selectedSegmentIndex = (inatToken && inatToken.length > 0) ? 0 : 1;
        
        [_listControl addTarget:self
                         action:@selector(changedSelection)
               forControlEvents:UIControlEventValueChanged];
    }
    return _listControl;
}

- (void)changedSelection {
    self.projectsFilterHasChanged = YES;
    [self.tableView reloadData];
}

- (UIBarButtonItem *)syncActivityItem {
    if (!_syncActivityItem) {
        UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 34, 25)];
        aiv.color = [UIColor inatTint];
        [aiv startAnimating];
        _syncActivityItem = [[UIBarButtonItem alloc] initWithCustomView:aiv];
    }
    return _syncActivityItem;
}


#pragma mark - View lifecycle

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"projectDetailSegue"]) {
        ProjectDetailV2ViewController *vc = [segue destinationViewController];
        vc.project = [sender isKindOfClass:[Project class]] ? sender : nil;
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
        
    self.tableView.estimatedRowHeight = 60.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = NSLocalizedString(@"Search for project named...",
                                                                    @"placeholder for project search field");
    self.searchController.searchResultsUpdater = self;
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = self.searchController;
    } else {
        self.tableView.tableHeaderView = self.searchController.searchBar;
    }
    self.definesPresentationContext = YES;

    
    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        [self.locationManager requestWhenInUseAuthorization];
        self.locationManager.delegate = self;
        self.locationManager.distanceFilter = 1000;
    }
    
    // try to sync "featured" projects automatically
    if ([[INatReachability sharedClient] isNetworkReachable]) {
        self.navigationItem.rightBarButtonItem = self.syncActivityItem;
        [self syncFeaturedProjects];

        // if the user is logged in, try to sync "joined" projects automatically
        INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
        if ([appDelegate.loginController isLoggedIn]) {
            [self syncUserProjects];
        }
    }
    
    
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 15 + 29 + 15, 0, 0);

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
    
    [self syncFinished];
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
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [[[RKClient sharedClient] requestQueue] cancelRequestsWithDelegate:self];
}

#pragma mark - button targets

- (IBAction)tappedSearch:(id)sender {
    [self.searchController setActive:YES];
    [self.searchController.searchBar becomeFirstResponder];    
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.projects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ProjectCell";
    ProjectTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    Project *p = [self.projects objectAtIndex:[indexPath row]];
    cell.titleLabel.text = p.title;
    [cell.projectImage cancelImageDownloadTask];
    [cell.projectImage setImageWithURL:[NSURL URLWithString:p.iconURL]
                      placeholderImage:[UIImage inat_defaultProjectImage]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Project *selectedProject = nil;
    
    // be defensive
    @try {
        selectedProject = [self.projects objectAtIndex:indexPath.item];
    }
    @catch (NSException *exception) {
        if ([exception.name isEqualToString:NSRangeException])
            selectedProject = nil;
        else
            @throw exception;
    }
    
    if (selectedProject && [selectedProject isKindOfClass:[Project class]])
        [self performSegueWithIdentifier:@"projectDetailSegue" sender:selectedProject];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [UIView new];
    view.frame = CGRectMake(0, 0, tableView.bounds.size.width, 50);
    
    view.backgroundColor = [UIColor whiteColor];
    
    UIView *separator = [UIView new];
    separator.frame = CGRectMake(0, 49.5f, tableView.bounds.size.width, 0.5f);
    separator.backgroundColor = [UIColor lightGrayColor];
    [view addSubview:separator];
    
    [view addSubview:self.listControl];
    self.listControl.center = view.center;
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.searchController.isActive) {
        return 0;
    } else {
        return 50;
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
        [self syncFeaturedProjects];
        [self syncNearbyProjects];
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
        
        for (Project *p in objects) {
            p.featuredAt = now;
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
    
    [self syncFinished];
    
    self.projectsFilterHasChanged = YES;
    [self.tableView reloadData];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    [self syncFinished];
    
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
        [self syncFinished];
        [self showSignupPrompt:nil];
    } else if (errorMsg) {
        [self syncFinished];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Whoops!",nil)
                                                                       message:[NSString stringWithFormat:NSLocalizedString(@"Looks like there was an error: %@",nil), errorMsg]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - UISearchResultsUpdating

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    // show local results
    self.projectsFilterHasChanged = YES;
    [self.tableView reloadData];
    
    // fetch remote results
    if (self.searchController.searchBar.text.length > 1) {
        NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
        NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
        NSString *path = [NSString stringWithFormat:@"/projects/search?locale=%@-%@&q=%@",
                          language, countryCode, self.searchController.searchBar.text];
        [self syncProjectsWithPath:path];
    }
}

@end
