//
//  ProjectsViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/12/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <FontAwesomeKit/FAKIonIcons.h>

#import "ProjectsViewController.h"
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

static const int ListControlIndexUser = 0;
static const int ListControlIndexFeatured = 1;
static const int ListControlIndexNearby = 2;

@interface ProjectsViewController () <UISearchResultsUpdating>
@property UISearchController *searchController;
@property BOOL projectsFilterHasChanged;

@property RLMResults *joinedProjects;
@property RLMNotificationToken *joinedToken;

@property NSArray *featuredProjects;
@property NSArray *nearbyProjects;
@property NSArray *matchingProjects;
@end

@implementation ProjectsViewController

- (ProjectsAPI *)projectsApi {
    static ProjectsAPI *_api = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _api = [[ProjectsAPI alloc] init];
    });
    return _api;
}

#pragma mark - these methods are loading locally from memory or realm

- (NSArray *)projects {
    if (self.searchController.isActive) {
        // show searched projects
        return self.matchingProjects;
    } else {
        // show projects for context
        switch (self.listControl.selectedSegmentIndex) {
            case ListControlIndexFeatured:
                return [self featuredProjects];
                break;
            case ListControlIndexNearby:
                return [self nearbyProjects];
                break;
            case ListControlIndexUser:
                return [self userProjects];
                break;
            default:
                return @[];
                break;
        }
    }
    
    return @[];
}

- (NSArray *)userProjects {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
    if (me) {
        // convert RLMResults to array
        return [self.joinedProjects valueForKey:@"self"];
    } else {
        return nil;
    }
}


#pragma mark - sync* methods are fetching from inaturalist.org

- (void)syncFeaturedProjects {
    __weak typeof(self)weakSelf = self;
    // TODO: handle per-site-id featuring
    [[self projectsApi] featuredProjectsHandler:^(NSArray *results, NSInteger count, NSError *error) {
        weakSelf.featuredProjects = results;
        [weakSelf.tableView reloadData];
    }];
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
    
    __weak typeof(self)weakSelf = self;
    [[self projectsApi] projectsNearLocation:self.lastLocation.coordinate
                                     handler:^(NSArray *results, NSInteger count, NSError *error) {
        
        weakSelf.nearbyProjects = results;
        [weakSelf.tableView reloadData];
    }];
}

- (void)syncUserProjects {
    // start by deleting all projects stored in realm
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm deleteObjects:[ExploreProjectRealm allObjects]];
    [realm commitWriteTransaction];
    
    // empty the UI
    [self.tableView reloadData];
    
    // fetch first page of joined projects, if we can
	INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
	if ([appDelegate.loginController isLoggedIn]) {
        ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
        [self syncUserProjectsUserId:me.userId page:1];
    } else {
        [self syncFinished];

        [self showSignupPrompt:NSLocalizedString(@"You must be logged in to sync user projects.", @"Signup prompt reason when user tries to sync user projects.")];
    }
}

- (void)syncUserProjectsUserId:(NSInteger)userId page:(NSInteger)page {
    __weak typeof(self)weakSelf = self;
    [[self projectsApi] projectsForUser:userId page:page handler:^(NSArray *results, NSInteger totalCount, NSError *error) {
        ExploreUserRealm *me = [ExploreUserRealm objectForPrimaryKey:@(userId)];
        if (!me) { return; }        // can't sync user projects if we have no user
        
        RLMRealm *realm = [RLMRealm defaultRealm];
        for (ExploreProject *eg in results) {
            NSDictionary *value = [ExploreProjectRealm valueForMantleModel:eg];
            [realm beginWriteTransaction];
            ExploreProjectRealm *project = [ExploreProjectRealm createOrUpdateInDefaultRealmWithValue:value];
            [me.joinedProjects addObject:project];
            [realm commitWriteTransaction];
        }

        // update tableview
        [weakSelf.tableView reloadData];
        
        NSInteger totalReceived = results.count + ((page-1) * [[weakSelf projectsApi] projectsPerPage]);
        if (totalReceived < totalCount) {
            // recursively fetch another page of joined projects
            [weakSelf syncUserProjectsUserId:userId page:page+1];
        }
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
        if ([sender isKindOfClass:[ExploreProject class]]) {
            // look for a (joined) project in realm, if one exists, pass _that_ to
            // project detail VC. this way we correctly show joined state, even if the
            // user is navigating to a project via via nearby or featured or searched
            // projects.
            ExploreProject *ep = (ExploreProject *)sender;
            ExploreProjectRealm *epr = [ExploreProjectRealm objectForPrimaryKey:@(ep.projectId)];
            if (epr) {
                vc.project = epr;
            } else {
                vc.project = ep;
            }
        } else {
            vc.project = sender;
        }
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
    
    // prime the joined projects results
    // and set up a trigger to reload the tableview every time
    // the joined projects list changes
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.loginController.isLoggedIn) {
        ExploreUserRealm *me = appDelegate.loginController.meUserLocal;
        if (me) {
            self.joinedProjects = me.joinedProjects;
            
            __weak typeof(self)weakSelf = self;
            self.joinedToken = [self.joinedProjects addNotificationBlock:^(RLMResults * _Nullable results, RLMCollectionChange * _Nullable change, NSError * _Nullable error) {
                [weakSelf.tableView reloadData];
            }];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
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
    [self.joinedToken invalidate];
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
    
    id <ProjectVisualization> project = [self.projects objectAtIndex:indexPath.row];
    cell.titleLabel.text = project.title;
    [cell.projectImage cancelImageDownloadTask];
    [cell.projectImage setImageWithURL:[project iconUrl]
                      placeholderImage:[UIImage inat_defaultProjectImage]];
        
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id <ProjectVisualization> selectedProject = nil;
    
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
    
    if (selectedProject && [selectedProject conformsToProtocol:@protocol(ProjectVisualization)]) {
        [self performSegueWithIdentifier:@"projectDetailSegue" sender:selectedProject];
    }
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
        [self syncNearbyProjects];
    }
}

#pragma mark - UISearchResultsUpdating

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    // show local results
    [self.tableView reloadData];
    
    // fetch remote results
    if (self.searchController.searchBar.text.length > 1) {
        __weak typeof(self)weakSelf = self;
        [[self projectsApi] projectsMatching:self.searchController.searchBar.text
                                     handler:^(NSArray *results, NSInteger count, NSError *error) {
            
            weakSelf.matchingProjects = results;
            [weakSelf.tableView reloadData];
        }];
    }
}

@end
