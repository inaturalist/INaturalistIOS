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
#import "User.h"
#import "OnboardingLoginViewController.h"
#import "INatReachability.h"

static const int ListControlIndexFeatured = 1;
static const int ListControlIndexNearby = 2;

@interface ProjectsViewController () <RKObjectLoaderDelegate, RKRequestDelegate>
@end

@implementation ProjectsViewController

#pragma mark - load* methods are loading locally from core data

- (void)loadData
{
    BOOL syncNeeded = NO;
    switch (self.listControl.selectedSegmentIndex) {
        case ListControlIndexFeatured:
            [self loadFeaturedProjects];
            syncNeeded = self.featuredProjectsSyncedAt ? NO : YES;
            break;
        case ListControlIndexNearby:
            [self loadNearbyProjects];
            syncNeeded = self.nearbyProjectsSyncedAt ? NO : YES;
            break;
        default:
            [self loadUserProjects];
            syncNeeded = self.projectUsersSyncedAt ? NO : YES;
            break;
    }
    [self checkEmpty];
    
    if (syncNeeded && [[INatReachability sharedClient] isNetworkReachable]) {
        [self sync];
    }
}

- (void)loadUserProjects {
    NSArray *projectUsers = [ProjectUser.all sortedArrayUsingComparator:^NSComparisonResult(ProjectUser *obj1, ProjectUser *obj2) {
        return [obj1.project.title.lowercaseString compare:obj2.project.title.lowercaseString];
    }];
    // be defensive
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"project != nil"];
    self.projects = [[projectUsers filteredArrayUsingPredicate:predicate] valueForKey:@"project"];
    [self.tableView reloadData];
}

- (void)loadFeaturedProjects {
    self.projects = [Project objectsWithPredicate:[NSPredicate predicateWithFormat:@"featuredAt != nil"]];
    [self.tableView reloadData];
}

- (void)loadNearbyProjects {
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
    NSArray *projectsSortedByNearness = [nearbyProjects sortedArrayUsingComparator:nearnessComparator];

    self.projects = projectsSortedByNearness;
    [self.tableView reloadData];
}

- (void)checkEmpty
{
    if (self.projects.count == 0 && !self.searchDisplayController.active) {
        if (self.noContentLabel) {
            [self.noContentLabel removeFromSuperview];
        } else {
            self.noContentLabel = [[UILabel alloc] init];
            self.noContentLabel.backgroundColor = [UIColor clearColor];
            self.noContentLabel.textColor = [UIColor grayColor];
            self.noContentLabel.textAlignment = NSTextAlignmentCenter;
            self.noContentLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        }
        
        if (self.listControl.selectedSegmentIndex == ListControlIndexFeatured) {
            self.noContentLabel.text = NSLocalizedString(@"No featured projects.", nil);
        } else if (self.listControl.selectedSegmentIndex == ListControlIndexNearby) {
            self.noContentLabel.text = NSLocalizedString(@"No nearby projects.",nil);
        } else {
            self.noContentLabel.text = NSLocalizedString(@"You haven't joined any projects yet.",nil);
        }
        self.noContentLabel.numberOfLines = 0;
        [self.noContentLabel sizeToFit];
        [self.noContentLabel setBounds:CGRectMake(0, 0, self.tableView.tableHeaderView.frame.size.width, 44)];
        self.noContentLabel.center = CGPointMake(self.tableView.center.x, 
                                                 self.tableView.tableHeaderView.frame.size.height +
                                                 (self.tableView.rowHeight * 2) + (self.tableView.rowHeight / 2));
        
        [self.view addSubview:self.noContentLabel];
    } else if (self.noContentLabel) {
        [self.noContentLabel removeFromSuperview];
    }
}

#pragma mark - sync* methods are fetching from inaturalist.org

- (void)sync
{
    self.navigationItem.rightBarButtonItem = self.syncActivityItem;
    switch (self.listControl.selectedSegmentIndex) {
        case ListControlIndexFeatured:
            [self syncFeaturedProjects];
            break;
        case ListControlIndexNearby:
            [self syncNearbyProjects];
            break;            
        default:
            [self syncUserProjects];
            break;
    }
}

- (void)syncFeaturedProjects {
    NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSString *path;
    if (self.lastLocation) {
        path = [NSString stringWithFormat:@"/projects.json?featured=true&latitude=%f&longitude=%f&locale=%@-%@",
                self.lastLocation.coordinate.latitude,
                self.lastLocation.coordinate.longitude,
                language,
                countryCode];
    } else {
        path = [NSString stringWithFormat:@"/projects.json?featured=true&locale=%@-%@",
                language,
                countryCode];
    }
    
    self.featuredProjectsSyncedAt = [NSDate date];
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
    
    self.nearbyProjectsSyncedAt = [NSDate date];
    [self syncProjectsWithPath:path];
}

- (void)syncUserProjects {
	INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
	if ([appDelegate.loginController isLoggedIn]) {
		User *me = [appDelegate.loginController fetchMe];
        NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
        NSString *language = [[NSLocale preferredLanguages] firstObject];
        NSString *path = [NSString stringWithFormat:@"/projects/user/%@.json?locale=%@-%@",
                          me.login,
                          language,
                          countryCode];
        
        self.projectUsersSyncedAt = [NSDate date];
        [self syncProjectsWithPath:path];
    } else {
        [self syncFinished];
        self.projectUsersSyncedAt = nil;

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


- (void)syncFinished
{
    self.navigationItem.rightBarButtonItem = self.searchButton;
}

- (UISegmentedControl *)listControl
{
    if (!_listControl) {
        _listControl = [[UISegmentedControl alloc] initWithItems:@[
                                                                   NSLocalizedString(@"Joined",nil),
                                                                   NSLocalizedString(@"Featured",nil),
                                                                   NSLocalizedString(@"Nearby",nil)
                                                                   ]];
        _listControl.tintColor = [UIColor inatTint];
        
        NSString *inatToken = [[NSUserDefaults standardUserDefaults] objectForKey:INatTokenPrefKey];
        _listControl.selectedSegmentIndex = (inatToken && inatToken.length > 0) ? 0 : 1;
        
        [_listControl addTarget:self action:@selector(loadData) forControlEvents:UIControlEventValueChanged];
    }
    return _listControl;
}

- (UIBarButtonItem *)syncActivityItem
{
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
            FAKIcon *briefcaseOutline = [FAKIonIcons iosBriefcaseOutlineIconWithSize:35];
            [briefcaseOutline addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
            [briefcaseOutline imageWithSize:CGSizeMake(34, 45)];
        });
        
        self.tabBarItem.selectedImage =({
            FAKIcon *briefcaseFilled = [FAKIonIcons iosBriefcaseIconWithSize:35];
            [briefcaseFilled addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
            [briefcaseFilled imageWithSize:CGSizeMake(34, 45)];
        });
        
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.contentOffset = CGPointMake(0, self.searchDisplayController.searchBar.frame.size.height);
    if (!self.projectsSearchController) {
        self.projectsSearchController = [[ProjectsSearchController alloc] 
                                         initWithSearchDisplayController:self.searchDisplayController];
    }
    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            [self.locationManager requestWhenInUseAuthorization];
        }
        self.locationManager.delegate = self;
        self.locationManager.distanceFilter = 1000;
    }
    
    // try to sync "featured" projects automatically
    if ([[INatReachability sharedClient] isNetworkReachable]) {
        self.navigationItem.rightBarButtonItem = self.syncActivityItem;
        [self syncFeaturedProjects];
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
    [self loadData];
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
    [self.searchDisplayController setActive:YES animated:YES];
    [self.searchDisplayController.searchBar becomeFirstResponder];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.projects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ProjectCell";
    
    ProjectTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[ProjectTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    Project *p = [self.projects objectAtIndex:[indexPath row]];
    cell.titleLabel.text = p.title;
    [cell.projectImage cancelImageRequestOperation];
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
    view.frame = CGRectMake(0, 0, tableView.bounds.size.width, 44);
    
    view.backgroundColor = [UIColor whiteColor];
    
    UIView *separator = [UIView new];
    separator.frame = CGRectMake(0, 43.5f, tableView.bounds.size.width, 0.5f);
    separator.backgroundColor = [UIColor lightGrayColor];
    [view addSubview:separator];
    
    [view addSubview:self.listControl];
    self.listControl.center = view.center;
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44;
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
    [self loadData];
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

@end
