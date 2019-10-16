//
//  GuidesViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/1/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <RestKit/RestKit.h>

#import "GuidesViewController.h"
#import "Guide.h"
#import "GuideXML.h"
#import "GuideCollectionViewController.h"
#import "GuideViewController.h"
#import "INaturalistAppDelegate.h"
#import "Analytics.h"
#import "TutorialSinglePageViewController.h"
#import "LoginController.h"
#import "UIImage+INaturalist.h"
#import "NSURL+INaturalist.h"
#import "UIColor+INaturalist.h"
#import "OnboardingLoginViewController.h"
#import "INatReachability.h"
#import "ExploreUserRealm.h"

static const int GuideCellImageTag = 1;
static const int GuideCellTitleTag = 2;

static const int ListControlIndexUser = 0;
static const int ListControlIndexNearby = 1;

@interface GuidesViewController () <RKRequestDelegate, RKObjectLoaderDelegate, UISearchResultsUpdating>
@property UISearchController *searchController;
@property NSArray *cachedGuides;
@property BOOL guidesFilterHasChanged;
@end

@implementation GuidesViewController

- (NSArray *)guides {
    if (self.guidesFilterHasChanged) {
        self.cachedGuides = nil;
        self.guidesFilterHasChanged = FALSE;
    }
    
    if (self.cachedGuides) {
        return self.cachedGuides;
    }
    
    if (self.searchController.isActive && self.searchController.searchBar.text.length > 0) {
        // show searched guide
        self.cachedGuides = [self filteredGuides:self.searchController.searchBar.text];
    } else {
        // show guides for selected context
        switch (self.listControl.selectedSegmentIndex) {
            case ListControlIndexUser:
                self.cachedGuides = [self userGuides];
                break;
            case ListControlIndexNearby:
                self.cachedGuides = [self nearbyGuides];
                break;
            default:
                self.cachedGuides = @[];
                break;
        }
    }
    
    return self.cachedGuides;
}

- (NSArray *)titleSortDescriptors {
    return @[
        [NSSortDescriptor sortDescriptorWithKey:@"title"
                                      ascending:YES],
    ];
}

- (NSArray *)filteredGuides:(NSString *)searchTerm {
    NSArray *guides = [Guide objectsWithPredicate:[NSPredicate predicateWithFormat:@"title contains[c] %@",
                                                       searchTerm]];
    return [guides sortedArrayUsingDescriptors:[self titleSortDescriptors]];
}

- (NSArray *)userGuides {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
    if (me) {
        NSPredicate *userGuidePredicate = [NSPredicate predicateWithFormat:@"userLogin = %@ OR ngzDownloadedAt != nil",
                                           me.login];
        NSArray *guides = [Guide objectsWithPredicate:userGuidePredicate];
        return [guides sortedArrayUsingDescriptors:[self titleSortDescriptors]];
    } else {
        return @[ ];
    }
}

- (NSArray *)nearbyGuides {
    NSFetchRequest *request = [Guide fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"latitude != nil && longitude != nil"];
    request.fetchLimit = 500;
    NSArray *unsortedGuides = [Guide objectsWithFetchRequest:request];
    NSMutableArray *guides = [NSMutableArray arrayWithArray:[unsortedGuides sortedArrayUsingComparator:^NSComparisonResult(Guide *p1, Guide *p2) {
        CLLocation *p1Location = [[CLLocation alloc] initWithLatitude:p1.latitude.doubleValue
                                                            longitude:p1.longitude.doubleValue];
        CLLocation *p2Location = [[CLLocation alloc] initWithLatitude:p2.latitude.doubleValue
                                                            longitude:p2.longitude.doubleValue];
        NSNumber *p1Distance = [NSNumber numberWithDouble:[self.lastLocation distanceFromLocation:p1Location]];
        NSNumber *p2Distance = [NSNumber numberWithDouble:[self.lastLocation distanceFromLocation:p2Location]];
        return [p1Distance compare:p2Distance];
    }]];
    [guides filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(Guide *p, NSDictionary *bindings) {
        CLLocation *loc = [[CLLocation alloc] initWithLatitude:p.latitude.doubleValue
                                                     longitude:p.longitude.doubleValue];
        NSNumber *d = [NSNumber numberWithDouble:[self.lastLocation distanceFromLocation:loc]];
        return d.doubleValue < 500000; // meters
    }]];
    return [NSArray arrayWithArray:guides];
}

#pragma mark - sync* methods fetch from inaturalist.org

- (void)syncNearbyGuides {
    NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSString *url =[NSString stringWithFormat:@"/guides.json?latitude=%f&longitude=%f&locale=%@-%@",
                    self.lastLocation.coordinate.latitude,
                    self.lastLocation.coordinate.longitude,
                    language,
                    countryCode];
    
    [self syncGuidesWithPath:url];
}

- (void)syncUserGuides {
	INaturalistAppDelegate *delegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    ExploreUserRealm *me = [delegate.loginController meUserLocal];
	if (me) {
    	NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
    	NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    	NSString *url =[NSString stringWithFormat:@"/guides/user/%@.json?locale=%@-%@",
                    	me.login, language, countryCode];
    	[self syncGuidesWithPath:url];
    } else {
        [self syncFinished];
    }
}

- (void)syncGuidesWithPath:(NSString *)urlString {
    [[Analytics sharedClient] debugLog:@"Network - Sync guides"];
    RKObjectManager *objectManager = [RKObjectManager sharedManager];
    [objectManager loadObjectsAtResourcePath:urlString
                                  usingBlock:^(RKObjectLoader *loader) {
                                      loader.delegate = self;
                                      loader.objectMapping = [Guide mapping];
                                  }];
}

- (void)syncFinished {
    self.navigationItem.rightBarButtonItem = self.searchButton;
}

- (void)presentSignupPrompt:(NSString *)reason {
    [[Analytics sharedClient] event:kAnalyticsEventNavigateOnboardingScreenLogin
                     withProperties:@{ @"via": @"guides" }];

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
    self.guidesFilterHasChanged = YES;
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"GuideDetailSegue"]) {
        GuideViewController *vc = [segue destinationViewController];
        Guide *g;
        if ([sender isKindOfClass:Guide.class]) {
            g = (Guide *)sender;
        } else {
            g = [self.guides
                          objectAtIndex:[[self.tableView
                                          indexPathForSelectedRow] row]];
        }
        GuideXML *gx = [[GuideXML alloc] initWithIdentifier:[g.recordID stringValue]];
        gx.xmlURL =[[NSURL URLWithString:[NSString stringWithFormat:@"/guides/%@.xml", g.recordID]
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
    
    // try to sync nearby guides automatically
    if ([[INatReachability sharedClient] isNetworkReachable]) {
        self.navigationItem.rightBarButtonItem = self.syncActivityItem;
        [self nearbyGuides];

        // if the user is logged in, try to sync user guides automatically
        INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
        if ([appDelegate.loginController isLoggedIn]) {
            [self syncUserGuides];
        }
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

- (void)dealloc {
    [[[RKClient sharedClient] requestQueue] cancelRequestsWithDelegate:self];
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
    
    Guide *p = [self.guides objectAtIndex:[indexPath row]];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:GuideCellImageTag];
    [imageView cancelImageDownloadTask];
    UILabel *title = (UILabel *)[cell viewWithTag:GuideCellTitleTag];
    title.text = p.title;
    title.textAlignment = NSTextAlignmentNatural;
    [imageView setImageWithURL:[NSURL URLWithString:p.iconURL]
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
- (void)guideViewControllerDownloadedNGZForGuide:(GuideXML *)guide
{
    Guide *g = [Guide objectWithPredicate:[NSPredicate predicateWithFormat:@"recordID = %@", guide.identifier]];
    if (g) {
        g.ngzDownloadedAt = guide.ngzDownloadedAt;
        [g save];
    }
}

- (void)guideViewControllerDeletedNGZForGuide:(GuideXML *)guide
{
    Guide *g = [Guide objectWithPredicate:[NSPredicate predicateWithFormat:@"recordID = %@", guide.identifier]];
    if (g) {
        g.ngzDownloadedAt = nil;
        [g save];
    }
}

#pragma mark - RKRequest and RKObjectLoader delegates

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    [self syncFinished];
    
    // KLUDGE!! RestKit doesn't seem to handle failed auth very well
    BOOL jsonParsingError = [error.domain isEqualToString:@"JKErrorDomain"] && error.code == -1;
    BOOL authFailure = [error.domain isEqualToString:@"NSURLErrorDomain"] && error.code == -1012;
    NSString *errorMsg = error.localizedDescription;
    
    if (jsonParsingError || authFailure) {
        [self presentSignupPrompt:nil];
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

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects {
    NSDate *now = [NSDate date];
    for (INatModel *o in objects) {
        Guide *g = (Guide *)o;
        [g setSyncedAt:now];
    }
    
    NSDate *yesterday = [now dateByAddingTimeInterval:-86400];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"syncedAt < %@ AND ngzDownloadedAt == nil",
                         yesterday];
    
    NSArray *rejects = [Guide objectsWithPredicate:pred];
    
    for (Guide *g in rejects) {
        [g deleteEntity];
    }
    
    NSError *error = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
    if (error) {
        NSString *logMsg = [NSString stringWithFormat:@"SAVE ERROR: %@",
                            error.localizedDescription];
        [[Analytics sharedClient] debugLog:logMsg];
    }
    
    [self syncFinished];
    
    self.guidesFilterHasChanged = YES;
    [self.tableView reloadData];
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
        [self presentSignupPrompt:nil];
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
    self.guidesFilterHasChanged = YES;
    [self.tableView reloadData];
    
    // fetch remote results
    if (self.searchController.searchBar.text.length > 1) {
        NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
        NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
        NSString *path = [NSString stringWithFormat:@"/guides/search?locale=%@-%@&q=%@",
                          language, countryCode, self.searchController.searchBar.text];
        [self syncGuidesWithPath:path];
    }
}


@end
