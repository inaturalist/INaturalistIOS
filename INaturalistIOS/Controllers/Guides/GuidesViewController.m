//
//  GuidesViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/1/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <FontAwesomeKit/FAKIonIcons.h>

#import "GuidesViewController.h"
#import "GuideXML.h"
#import "GuideCollectionViewController.h"
#import "GuideViewController.h"
#import "INaturalistAppDelegate.h"
#import "TutorialSinglePageViewController.h"
#import "LoginController.h"
#import "UIImage+INaturalist.h"
#import "NSURL+INaturalist.h"
#import "UIColor+INaturalist.h"
#import "OnboardingLoginViewController.h"
#import "INatReachability.h"
#import "ExploreUserRealm.h"
#import "GuidesAPI.h"
#import "ExploreGuide.h"
#import "ExploreGuideRealm.h"

static const int GuideCellImageTag = 1;
static const int GuideCellTitleTag = 2;

static const int ListControlIndexUser = 0;
static const int ListControlIndexNearby = 1;

@interface GuidesViewController () <UISearchResultsUpdating>
@property UISearchController *searchController;
@property RLMResults *userRealmGuides;
@end

@implementation GuidesViewController

- (GuidesAPI *)guidesApi {
    static GuidesAPI *_api = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _api = [[GuidesAPI alloc] init];
    });
    return _api;
}

- (NSArray *)guides {
    if (self.searchController.isActive && self.searchController.searchBar.text.length > 0) {
        return [self filteredGuides:self.searchController.searchBar.text];
    } else {
        // show guides for selected context
        switch (self.listControl.selectedSegmentIndex) {
            case ListControlIndexUser:
                return [self userGuides];
                break;
            case ListControlIndexNearby:
                return [self nearbyGuides];
                break;
            default:
                return nil;
                break;
        }
    }
}

- (NSArray <RLMSortDescriptor *> *)titleSortDescriptors {
    return @[
        [RLMSortDescriptor sortDescriptorWithKeyPath:@"title"
                                           ascending:YES],
    ];
}

- (NSArray *)filteredGuides:(NSString *)searchTerm {
    NSPredicate *titleSearchPredicate = [NSPredicate predicateWithFormat:@"title contains[c] %@", searchTerm];
    RLMResults *results = [ExploreGuideRealm objectsWithPredicate:titleSearchPredicate];
    RLMResults *sortedResults = [results sortedResultsUsingDescriptors:[self titleSortDescriptors]];
    // convert RLMResults to array
    return [sortedResults valueForKey:@"self"];
}

- (NSArray *)userGuides {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
    if (me) {
        NSPredicate *userGuidePredicate = [NSPredicate predicateWithFormat:@"userLogin = %@ OR ngzDownloadedAt != nil",
                                           me.login];
        RLMResults *results = [ExploreGuideRealm objectsWithPredicate:userGuidePredicate];
        RLMResults *sortedResults =  [results sortedResultsUsingDescriptors:[self titleSortDescriptors]];
        // convert RLMResults to array
        return [sortedResults valueForKey:@"self"];
    } else {
        return nil;
    }
}

- (NSArray *)nearbyGuides {
    NSPredicate *validLocationPredicate = [NSPredicate predicateWithFormat:@"latitude != %f && longitude != %f",
                                           kCLLocationCoordinate2DInvalid.latitude,
                                           kCLLocationCoordinate2DInvalid.longitude];
    
    RLMResults *candidates = [ExploreGuideRealm objectsWithPredicate:validLocationPredicate];
    // convert RLMResults to array, realm has no way to sort using computed values
    NSArray *unsortedGuides = [candidates valueForKey:@"self"];
    
    
    NSMutableArray *guides = [[unsortedGuides sortedArrayUsingComparator:^NSComparisonResult(ExploreGuideRealm *p1, ExploreGuideRealm *p2) {
        CLLocation *p1Location = [[CLLocation alloc] initWithLatitude:p1.latitude
                                                            longitude:p1.longitude];
        CLLocation *p2Location = [[CLLocation alloc] initWithLatitude:p2.latitude
                                                            longitude:p2.longitude];
        NSNumber *p1Distance = [NSNumber numberWithDouble:[self.lastLocation distanceFromLocation:p1Location]];
        NSNumber *p2Distance = [NSNumber numberWithDouble:[self.lastLocation distanceFromLocation:p2Location]];
        return [p1Distance compare:p2Distance];
    }] mutableCopy];
    [guides filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(ExploreGuideRealm *p, NSDictionary *bindings) {
        CLLocation *loc = [[CLLocation alloc] initWithLatitude:p.latitude
                                                     longitude:p.longitude];
        NSNumber *d = [NSNumber numberWithDouble:[self.lastLocation distanceFromLocation:loc]];
        return d.doubleValue < 500000; // meters
    }]];
    
    return [NSArray arrayWithArray:guides];
}

#pragma mark - sync* methods fetch from inaturalist.org

- (void)syncNearbyGuides {
    if (self.lastLocation) {
        __weak typeof(self) weakSelf = self;
        [[self guidesApi] guidesNearLocation:self.lastLocation.coordinate
                                     handler:^(NSArray *results, NSInteger count, NSError *error) {
            
            RLMRealm *realm = [RLMRealm defaultRealm];
            [realm beginWriteTransaction];
            for (ExploreGuide *eg in results) {
                id value = [ExploreGuideRealm valueForMantleModel:eg];
                [ExploreGuideRealm createOrUpdateInRealm:realm withValue:value];
            }
            [realm commitWriteTransaction];
            [weakSelf.tableView reloadData];
        }];
    } else {
        [self syncFinished];
    }
}

- (void)syncUserGuides {
	INaturalistAppDelegate *delegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
	if (delegate.loginController.isLoggedIn) {
        __weak typeof(self) weakSelf = self;
        [[self guidesApi] guidesForLoggedInUserHandler:^(NSArray *results, NSInteger count, NSError *error) {
            RLMRealm *realm = [RLMRealm defaultRealm];
            [realm beginWriteTransaction];
            for (ExploreGuide *eg in results) {
                id value = [ExploreGuideRealm valueForMantleModel:eg];
                [ExploreGuideRealm createOrUpdateInDefaultRealmWithValue:value];
            }
            [realm commitWriteTransaction];
            [weakSelf.tableView reloadData];
        }];
    } else {
        [self syncFinished];
    }
}

- (void)syncFinished {
    self.navigationItem.rightBarButtonItem = self.searchButton;
}

- (void)presentSignupPrompt:(NSString *)reason {
    __weak typeof(self) weakSelf = self;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Onboarding" bundle:nil];
    OnboardingLoginViewController *login = [storyboard instantiateViewControllerWithIdentifier:@"onboarding-login"];
    login.skippable = NO;
    login.closeAction = ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        // switch back to nearby
        [strongSelf.listControl setSelectedSegmentIndex:ListControlIndexNearby];
        [strongSelf dismissViewControllerAnimated:YES completion:nil];
    };
    [weakSelf presentViewController:login animated:YES completion:nil];
}

- (UIBarButtonItem *)listControlItem {
    if (!_listControlItem) {
        _listControlItem = [[UIBarButtonItem alloc] initWithCustomView:self.listControl];
    }
    return _listControlItem;
}


- (UISegmentedControl *)listControl {
    if (!_listControl) {
        _listControl = [[UISegmentedControl alloc] initWithItems:@[
            NSLocalizedString(@"Your Guides",nil),
            NSLocalizedString(@"Nearby",nil),
        ]];
        _listControl.tintColor = [UIColor inatTint];

        NSString *inatToken = [[NSUserDefaults standardUserDefaults] objectForKey:INatTokenPrefKey];
        _listControl.selectedSegmentIndex = (inatToken && inatToken.length > 0) ? ListControlIndexUser : ListControlIndexNearby;
        
        [_listControl addTarget:self action:@selector(changedSelection) forControlEvents:UIControlEventValueChanged];
    }
    return _listControl;
}

- (void)changedSelection {
    [self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"GuideDetailSegue"]) {
        GuideViewController *vc = [segue destinationViewController];
        ExploreGuideRealm *g = [self.guides objectAtIndex:[[self.tableView indexPathForSelectedRow] row]];
        NSString *guideIdString = [NSString stringWithFormat:@"%ld", (long)g.guideId];
        GuideXML *gx = [[GuideXML alloc] initWithIdentifier:guideIdString];
        gx.xmlURL =[[NSURL URLWithString:[NSString stringWithFormat:@"/guides/%ld.xml", (long)g.guideId]
                           relativeToURL:[NSURL inat_baseURL]] absoluteString];
        vc.guide = gx;
        vc.title = g.title;
        vc.guideDelegate = self;
    }
}

#pragma mark - View lifecycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        
        self.title = NSLocalizedString(@"Guides", nil);

        self.tabBarItem.image = ({
            FAKIcon *bookInactive = [FAKIonIcons iosBookIconWithSize:35];
            [bookInactive addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor]];
            [[bookInactive imageWithSize:CGSizeMake(34, 45)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        });
        
        self.tabBarItem.selectedImage = ({
            FAKIcon *bookActive = [FAKIonIcons iosBookIconWithSize:35];
            [bookActive addAttribute:NSForegroundColorAttributeName value:[UIColor inatTint]];
            [[bookActive imageWithSize:CGSizeMake(34, 45)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
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
    self.searchController.searchBar.placeholder = NSLocalizedString(@"Search for guide named...",
                                                                    @"placeholder for guide search field");
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
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];

    // try to sync nearby guides automatically
    if ([[INatReachability sharedClient] isNetworkReachable]) {
        [self nearbyGuides];

        // if the user is logged in, try to sync user guides automatically
        if ([appDelegate.loginController isLoggedIn]) {
            [self syncUserGuides];
        }
    }
    
    // setup user guides
    ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
    if (me) {
        NSPredicate *userGuidePredicate = [NSPredicate predicateWithFormat:@"userLogin = %@ OR ngzDownloadedAt != nil",
                                           me.login];
        self.userRealmGuides = [ExploreGuideRealm objectsWithPredicate:userGuidePredicate];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.locationManager) {
        [self.locationManager stopUpdatingLocation];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsKeyOldTutorialSeen] &&
        ![[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsKeyTutorialNeverAgain] &&
        ![[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsKeyTutorialSeenGuides]) {
        
        TutorialSinglePageViewController *vc = [[TutorialSinglePageViewController alloc] initWithNibName:nil bundle:nil];
        vc.tutorialImage = [UIImage imageNamed:@"tutorial_guides"];
        vc.tutorialTitle = NSLocalizedString(@"Guides are lists of species", @"Title for guides tutorial screen");
        vc.tutorialSubtitleOne = NSLocalizedString(@"Guides are created and shared by the iNaturalist community", @"Subtitle above image for guides tutorial screen");
        vc.tutorialSubtitleTwo = NSLocalizedString(@"Visit iNaturalist.org to create your own guides", @"Subtitle below image for guides tutorial screen");

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self presentViewController:vc animated:YES completion:nil];
        });
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDefaultsKeyTutorialSeenGuides];
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

#pragma mark - button targets

- (IBAction)tappedSearch:(id)sender {
    [self.searchController setActive:YES];
    [self.searchController.searchBar becomeFirstResponder];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.guides.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"GuideCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    ExploreGuideRealm *guide = [self.guides objectAtIndex:[indexPath row]];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:GuideCellImageTag];
    [imageView cancelImageDownloadTask];
    UILabel *title = (UILabel *)[cell viewWithTag:GuideCellTitleTag];
    title.text = guide.title;
    title.textAlignment = NSTextAlignmentNatural;
    [imageView setImageWithURL:guide.iconURL
              placeholderImage:[UIImage inat_defaultGuideImage]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"GuideDetailSegue" sender:self];
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
    // flag if we should sync location-based guides
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
        [self syncNearbyGuides];
    }
}

#pragma mark - GuideViewControllerDelegate
- (void)guideViewControllerDownloadedNGZForGuide:(GuideXML *)guide {
    ExploreGuideRealm *g = [ExploreGuideRealm objectForPrimaryKey:@( [[guide identifier] integerValue])];
    if (g) {
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        g.ngzDownloadedAt = guide.ngzDownloadedAt;
        [realm commitWriteTransaction];
        [self.tableView reloadData];
    }
}

- (void)guideViewControllerDeletedNGZForGuide:(GuideXML *)guide {
    ExploreGuideRealm *g = [ExploreGuideRealm objectForPrimaryKey:@( [[guide identifier] integerValue])];
    if (g) {
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        g.ngzDownloadedAt = nil;
        [realm commitWriteTransaction];
        [self.tableView reloadData];
    }
}

#pragma mark - UISearchResultsUpdating

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    // show local results
    [self.tableView reloadData];
    
    // fetch remote results
    if (self.searchController.searchBar.text.length > 1) {
        __weak typeof(self) weakSelf = self;
        [[self guidesApi] guidesMatching:self.searchController.searchBar.text
                                 handler:^(NSArray *results, NSInteger count, NSError *error) {
            RLMRealm *realm = [RLMRealm defaultRealm];
            [realm beginWriteTransaction];
            for (ExploreGuide *eg in results) {
                id value = [ExploreGuideRealm valueForMantleModel:eg];
                [ExploreGuideRealm createOrUpdateInRealm:realm withValue:value];
            }
            [realm commitWriteTransaction];
            [weakSelf.tableView reloadData];
        }];
    }
}


@end
