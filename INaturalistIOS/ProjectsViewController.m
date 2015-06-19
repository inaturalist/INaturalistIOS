//
//  ProjectsViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/12/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <FontAwesomeKit/FAKIonIcons.h>

#import "ProjectsViewController.h"
#import "ProjectListViewController.h"
#import "Project.h"
#import "ProjectUser.h"
#import "Analytics.h"
#import "TutorialSinglePageViewController.h"
#import "SignupSplashViewController.h"
#import "INaturalistAppDelegate.h"
#import "INaturalistAppDelegate+TransitionAnimators.h"
#import "LoginController.h"
#import "UIImage+INaturalist.h"

static const int ProjectCellImageTag = 1;
static const int ProjectCellTitleTag = 2;
static const int ListControlIndexFeatured = 1;
static const int ListControlIndexNearby = 2;

@implementation ProjectsViewController
@synthesize projects = _projects;
@synthesize projectUsersSyncedAt = _lastSyncedAt;
@synthesize featuredProjectsSyncedAt = _featuredProjectsSyncedAt;
@synthesize nearbyProjectsSyncedAt = _nearbyProjectsSyncedAt;
@synthesize noContentLabel = _noContentLabel;
@synthesize projectsSearchController = _projectsSearchController;
@synthesize listControl = _listControl;
@synthesize listControlItem = _listControlItem;
@synthesize locationManager = _locationManager;
@synthesize lastLocation = _lastLocation;
@synthesize syncButton = _syncButton;
@synthesize syncActivityItem = _syncActivityItem;

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
    
    if (syncNeeded && [[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
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

- (IBAction)clickedSync:(id)sender {
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Network unreachable",nil)
                                                     message:NSLocalizedString(@"You must be connected to the Internet to sync.",nil)
                                                    delegate:self 
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
        [av show];
        return;
    }
    [self sync];
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
    NSString *path = [NSString stringWithFormat:@"/projects.json?featured=true&locale=%@-%@", language, countryCode];
    
    self.featuredProjectsSyncedAt = [NSDate date];
    [self syncProjectsWithPath:path];
}

- (void)syncNearbyProjects {
    if (!self.lastLocation) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Couldn't determine your location",nil)
                                                     message:NSLocalizedString(@"Make sure iNat has permission to access your location or give the GPS some time to fetch it.",nil)
                                                    delegate:self 
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
        [av show];
        [self stopSync];
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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *username = [defaults objectForKey:INatUsernamePrefKey];
    if (username && username.length > 0) {
        NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
        NSString *language = [[NSLocale preferredLanguages] firstObject];
        NSString *path = [NSString stringWithFormat:@"/projects/user/%@.json?locale=%@-%@",
                          username,
                          language,
                          countryCode];
        
        self.projectUsersSyncedAt = [NSDate date];
        [self syncProjectsWithPath:path];
    } else {
        [self stopSync];
        self.projectUsersSyncedAt = nil;

        [[Analytics sharedClient] event:kAnalyticsEventNavigateSignupSplash
                         withProperties:@{ @"From": @"Projects" }];

        SignupSplashViewController *splash = [[SignupSplashViewController alloc] initWithNibName:nil bundle:nil];
        splash.reason = NSLocalizedString(@"You must be logged in to sync user projects.", @"Signup prompt reason when user tries to sync user projects.");
        splash.skippable = NO;
        splash.cancellable = YES;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:splash];
        nav.delegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
    }
}

- (void)syncProjectsWithPath:(NSString *)path {
    
    __weak typeof(self) weakSelf = self;

    RKObjectLoaderDidLoadObjectsBlock didLoadObjectsBlock = ^(NSArray *objects) {
        NSDate *now = [NSDate date];
        for (INatModel *o in objects) {
            [o setSyncedAt:now];
        }
        
        if ([path rangeOfString:@"featured"].location != NSNotFound) {
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
        } else if ([path rangeOfString:@"projects/user"].location != NSNotFound) {
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
        
        [weakSelf stopSync];
        [weakSelf loadData];
    };
    
    RKRequestDidLoadResponseBlock didLoadResponseBlock = ^(RKResponse *response) {
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
            [weakSelf stopSync];
            [weakSelf showSignupPrompt];
        } else if (errorMsg) {
            [weakSelf stopSync];
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Whoops!",nil)
                                                         message:[NSString stringWithFormat:NSLocalizedString(@"Looks like there was an error: %@",nil), errorMsg]
                                                        delegate:nil
                                               cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                               otherButtonTitles:nil];
            [av show];
        }
    };
    
    RKObjectLoaderDidFailWithErrorBlock didFailBlock = ^(NSError *error) {
        
        [weakSelf stopSync];
        
        // KLUDGE!! RestKit doesn't seem to handle failed auth very well
        BOOL jsonParsingError = [error.domain isEqualToString:@"JKErrorDomain"] && error.code == -1;
        BOOL authFailure = [error.domain isEqualToString:@"NSURLErrorDomain"] && error.code == -1012;
        NSString *errorMsg = error.localizedDescription;
        
        if (jsonParsingError || authFailure) {
            [weakSelf showSignupPrompt];
        } else {
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Whoops!",nil)
                                                         message:[NSString stringWithFormat:NSLocalizedString(@"Looks like there was an error: %@",nil), errorMsg]
                                                        delegate:nil
                                               cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                               otherButtonTitles:nil];
            [av show];
        }
        
    };
    
    RKObjectMapping *mapping = nil;
    if ([path rangeOfString:@"projects/user"].location != NSNotFound) {
        mapping = [ProjectUser mapping];
    } else {
        mapping = [Project mapping];
    }
    
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:path
                                                    usingBlock:^(RKObjectLoader *loader) {
                                                        loader.objectMapping = mapping;
                                                        
                                                        loader.onDidLoadObjects = didLoadObjectsBlock;
                                                        loader.onDidLoadResponse = didLoadResponseBlock;
                                                        loader.onDidFailWithError = didFailBlock;
                                                    }];
    
}

- (void)showSignupPrompt {
    __weak typeof(self) weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kUserLoggedInNotificationName
                                                      object:self
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      __strong typeof(weakSelf) strongSelf = weakSelf;
                                                      strongSelf.projectUsersSyncedAt = nil;
                                                      [weakSelf sync];
                                                  }];
    
    [[Analytics sharedClient] event:kAnalyticsEventNavigateSignupSplash
                     withProperties:@{ @"From": @"Projects" }];

    SignupSplashViewController *svc = [[SignupSplashViewController alloc] initWithNibName:nil bundle:nil];
    svc.cancellable = YES;
    svc.skippable = NO;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:svc];
    // for sizzle
    nav.delegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
    [self.tabBarController presentViewController:nav
                                        animated:YES
                                      completion:nil];
}


- (void)stopSync
{
    self.navigationItem.rightBarButtonItem = self.syncButton;
    [[[[RKObjectManager sharedManager] client] requestQueue] cancelAllRequests];
}

- (UIBarButtonItem *)listControlItem
{
    if (!_listControlItem) {
        _listControlItem = [[UIBarButtonItem alloc] initWithCustomView:self.listControl];
    }
    return _listControlItem;
}

- (UISegmentedControl *)listControl
{
    if (!_listControl) {
        _listControl = [[UISegmentedControl alloc] initWithItems:@[
                                                                   NSLocalizedString(@"Joined",nil),
                                                                   NSLocalizedString(@"Featured",nil),
                                                                   NSLocalizedString(@"Nearby",nil)
                                                                   ]];
        
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
        [aiv startAnimating];
        _syncActivityItem = [[UIBarButtonItem alloc] initWithCustomView:aiv];
    }
    return _syncActivityItem;
}


#pragma mark - View lifecycle

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ProjectListSegue"]) {
        ProjectListViewController *vc = [segue destinationViewController];
        vc.project = [sender isKindOfClass:[Project class]] ? sender : nil;
    }
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        
        self.navigationController.tabBarItem.image = ({
            FAKIcon *briefcaseOutline = [FAKIonIcons iosBriefcaseOutlineIconWithSize:35];
            [briefcaseOutline addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
            [briefcaseOutline imageWithSize:CGSizeMake(34, 45)];
        });
        
        self.navigationController.tabBarItem.selectedImage =({
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
    if ([RKClient sharedClient].reachabilityObserver.isReachabilityDetermined &&
        [RKClient sharedClient].reachabilityObserver.isNetworkReachable) {
        
        self.navigationItem.rightBarButtonItem = self.syncActivityItem;
        [self syncFeaturedProjects];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableView deselectRowAtIndexPath:[self.tableView.indexPathsForSelectedRows objectAtIndex:0] animated:YES];
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationController setToolbarHidden:NO];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self setToolbarItems:[NSArray arrayWithObjects:
                           flex,
                           self.listControlItem,
                           flex, 
                           nil]];
    
    if (self.locationManager) {
        [self.locationManager startUpdatingLocation];
    }
    [self loadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self stopSync];
    if (self.locationManager) {
        [self.locationManager stopUpdatingLocation];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateProjects];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsKeyOldTutorialSeen] &&
        ![[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsKeyTutorialNeverAgain] &&
        ![[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsKeyTutorialSeenProjects]) {
        
        TutorialSinglePageViewController *vc = [[TutorialSinglePageViewController alloc] initWithNibName:nil bundle:nil];
        vc.tutorialImage = [UIImage imageNamed:@"tutorial_projects"];
        vc.tutorialTitle = NSLocalizedString(@"Projects are collections of observations with a common purpose", @"Title for projects tutorial screen");
        vc.tutorialSubtitleOne = NSLocalizedString(@"Join projects to select them when you record observations", @"Subtitle above image for projects tutorial screen");
        vc.tutorialSubtitleTwo = NSLocalizedString(@"Visit iNaturalist.org to create your own projects", @"Subtitle below image for projects tutorial screen");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self presentViewController:vc animated:YES completion:nil];
        });
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDefaultsKeyTutorialSeenProjects];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateProjects];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.projects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ProjectCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    Project *p = [self.projects objectAtIndex:[indexPath row]];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:ProjectCellImageTag];
    [imageView sd_cancelCurrentImageLoad];
    UILabel *title = (UILabel *)[cell viewWithTag:ProjectCellTitleTag];
    title.text = p.title;
    [imageView sd_setImageWithURL:[NSURL URLWithString:p.iconURL]
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
        [self performSegueWithIdentifier:@"ProjectListSegue" sender:selectedProject];
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    self.lastLocation = newLocation;
}

@end
