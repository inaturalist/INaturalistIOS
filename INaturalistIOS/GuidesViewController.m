//
//  GuidesViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/1/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <FontAwesomeKit/FAKIonIcons.h>

#import "GuidesViewController.h"
#import "Guide.h"
#import "GuideXML.h"
#import "GuideCollectionViewController.h"
#import "GuideViewController.h"
#import "INaturalistAppDelegate.h"
#import "INaturalistAppDelegate+TransitionAnimators.h"
#import "Analytics.h"
#import "TutorialSinglePageViewController.h"
#import "SignupSplashViewController.h"
#import "LoginController.h"
#import "UIImage+INaturalist.h"
#import "NSURL+INaturalist.h"
#import "UIColor+INaturalist.h"

static const int GuideCellImageTag = 1;
static const int GuideCellTitleTag = 2;
static const int ListControlIndexAll = 0;
static const int ListControlIndexUser = 1;
static const int ListControlIndexNearby = 2;

@interface GuidesViewController () <RKRequestDelegate, RKObjectLoaderDelegate>
@end

@implementation GuidesViewController

- (void)loadData
{
    BOOL syncNeeded = NO;
    switch (self.listControl.selectedSegmentIndex) {
        case ListControlIndexAll:
            [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
            [self loadAllGuides];
            syncNeeded = self.allGuidesSyncedAt ? NO : YES;
            break;
        case ListControlIndexNearby:
            [self loadNearbyGuides];
            syncNeeded = self.nearbyGuidesSyncedAt ? NO : YES;
            break;
        default:
            [self loadUserGuides];
            syncNeeded = self.guideUsersSyncedAt ? NO : YES;
            break;
    }
    [self checkEmpty];
    [self.tableView reloadData];
    
    if (syncNeeded &&
        [RKClient sharedClient].reachabilityObserver.isReachabilityDetermined &&
        [RKClient sharedClient].reachabilityObserver.isNetworkReachable) {
        
        [self sync:NO];
    } else {
        [self syncFinished];
    }
}

- (void)loadAllGuides
{
    self.guides = [Guide.all sortedArrayUsingComparator:^NSComparisonResult(Guide *g1, Guide *g2) {
        return [g1.title.lowercaseString compare:g2.title.lowercaseString];
    }];
}

- (void)loadUserGuides
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *username = [defaults objectForKey:INatUsernamePrefKey];
    NSMutableArray *unsortedGuides = [NSMutableArray arrayWithArray:[Guide objectsWithPredicate:[NSPredicate predicateWithFormat:@"userLogin = %@ OR ngzDownloadedAt != nil", username]]];
    self.guides = [unsortedGuides sortedArrayUsingComparator:^NSComparisonResult(Guide *g1, Guide *g2) {
        return [g1.title.lowercaseString compare:g2.title.lowercaseString];
    }];
}

- (void)loadFeaturedGuides
{
    self.guides = [NSMutableArray arrayWithArray:[Guide objectsWithPredicate:[NSPredicate predicateWithFormat:@"featuredAt != nil"]]];
}

- (void)loadNearbyGuides
{
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
    self.guides = [NSArray arrayWithArray:guides];
}

- (IBAction)clickedSync:(id)sender {
    if ([RKClient sharedClient].reachabilityObserver.isReachabilityDetermined &&
        [RKClient sharedClient].reachabilityObserver.isNetworkReachable) {
        
        [self sync:YES];
    } else {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Network unreachable",nil)
                                                     message:NSLocalizedString(@"You must be connected to the Internet to sync.",nil)
                                                    delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
        [av show];
    }
}

- (void)checkEmpty
{
    if (self.guides.count == 0 && !self.searchDisplayController.active) {
        if (self.noContentLabel) {
            [self.noContentLabel removeFromSuperview];
        } else {
            self.noContentLabel = [[UILabel alloc] init];
            self.noContentLabel.backgroundColor = [UIColor clearColor];
            self.noContentLabel.textColor = [UIColor grayColor];
            self.noContentLabel.textAlignment = NSTextAlignmentCenter;
            self.noContentLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        }
        
        if (self.listControl.selectedSegmentIndex == ListControlIndexNearby) {
            self.noContentLabel.text = NSLocalizedString(@"No nearby guides.",nil);
        } else {
            self.noContentLabel.text = NSLocalizedString(@"You haven't created or downloaded any guides yet.",nil);
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
    [self sync:NO];
}

- (void)sync:(BOOL)explicit
{
    self.navigationItem.rightBarButtonItem = self.syncActivityItem;
    switch (self.listControl.selectedSegmentIndex) {
        case ListControlIndexAll:
            [self syncAllGuides];
            break;
        case ListControlIndexNearby:
            [self syncNearbyGuides:explicit];
            break;
        default:
            if ([(INaturalistAppDelegate *)UIApplication.sharedApplication.delegate loggedIn]) {
                [self syncUserGuides];
            } else {
                self.navigationItem.rightBarButtonItem = self.syncButton;
            }
            break;
    }
}

- (void)syncAllGuides
{
    self.allGuidesSyncedAt = [NSDate date];
    NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSString *url =[NSString stringWithFormat:@"/guides.json?locale=%@-%@",
                    language,
                    countryCode];
    [self syncGuidesWithUrlString:url];
}

- (void)syncNearbyGuides
{
    [self syncNearbyGuides:NO];
}

- (void)syncNearbyGuides:(BOOL)explicit
{
    if (!self.lastLocation) {
        if (explicit) {
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Couldn't determine your location",nil)
                                                         message:NSLocalizedString(@"Make sure iNat has permission to access your location or give the GPS some time to fetch it.",nil)
                                                        delegate:self
                                               cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                               otherButtonTitles:nil];
            [av show];
        }
        [self syncFinished];
        return;
    }
    self.nearbyGuidesSyncedAt = [NSDate date];
    NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSString *url =[NSString stringWithFormat:@"/guides.json?latitude=%f&longitude=%f&locale=%@-%@",
                    self.lastLocation.coordinate.latitude,
                    self.lastLocation.coordinate.longitude,
                    language,
                    countryCode];
    
    [self syncGuidesWithUrlString:url];
}

- (void)syncUserGuides
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *username = [defaults objectForKey:INatUsernamePrefKey];
    NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSString *url =[NSString stringWithFormat:@"/guides/user/%@.json?locale=%@-%@",
                    username,
                    language,
                    countryCode];
    if (username && username.length > 0) {
        [self syncGuidesWithUrlString:url];
        self.guideUsersSyncedAt = [NSDate date];
    } else {
        [self syncFinished];
    }
}

- (void)syncGuidesWithUrlString:(NSString *)urlString {
    [[Analytics sharedClient] debugLog:@"Network - Sync guides"];
    RKObjectManager *objectManager = [RKObjectManager sharedManager];
    [objectManager loadObjectsAtResourcePath:urlString
                                  usingBlock:^(RKObjectLoader *loader) {
                                      loader.delegate = self;
                                      loader.objectMapping = [Guide mapping];
                                  }];
}

- (void)syncFinished
{
    self.navigationItem.rightBarButtonItem = self.syncButton;
}
    
- (void)showSignupPrompt {
    __weak typeof(self) weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kUserLoggedInNotificationName
                                                      object:self
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      __strong typeof(weakSelf)strongSelf = weakSelf;
                                                      strongSelf.guideUsersSyncedAt = nil;
                                                      [strongSelf sync];
                                                  }];
    
    [[Analytics sharedClient] event:kAnalyticsEventNavigateSignupSplash
                     withProperties:@{ @"From": @"Guides" }];

    SignupSplashViewController *svc = [[SignupSplashViewController alloc] initWithNibName:nil bundle:nil];
    svc.skippable = NO;
    svc.cancellable = YES;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:svc];
    // for sizzle
    nav.delegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
    [self.tabBarController presentViewController:nav
                                        animated:YES
                                      completion:nil];
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
                                                                   NSLocalizedString(@"All",nil),
                                                                   NSLocalizedString(@"Your Guides",nil),
                                                                   NSLocalizedString(@"Nearby",nil),
                                                                   ]];
        _listControl.tintColor = [UIColor inatTint];

        NSString *inatToken = [[NSUserDefaults standardUserDefaults] objectForKey:INatTokenPrefKey];
        _listControl.selectedSegmentIndex = (inatToken && inatToken.length > 0) ? ListControlIndexUser : ListControlIndexNearby;
        
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
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
            FAKIcon *bookOutline = [FAKIonIcons iosBookOutlineIconWithSize:35];
            [bookOutline addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
            [bookOutline imageWithSize:CGSizeMake(34, 45)];
        });
        
        self.tabBarItem.selectedImage =({
            FAKIcon *bookFilled = [FAKIonIcons iosBookIconWithSize:35];
            [bookFilled addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
            [bookFilled imageWithSize:CGSizeMake(34, 45)];
        });
        
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.contentOffset = CGPointMake(0, self.searchDisplayController.searchBar.frame.size.height);
    if (!self.guidesSearchController) {
        self.guidesSearchController = [[GuidesSearchController alloc]
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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView deselectRowAtIndexPath:[self.tableView.indexPathsForSelectedRows objectAtIndex:0] animated:YES];
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationController setToolbarHidden:NO];
    [self.navigationController.toolbar setBarStyle:UIBarStyleDefault];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self setToolbarItems:[NSArray arrayWithObjects:
                           flex,
                           self.listControlItem,
                           flex,
                           nil]];
    
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
    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateGuides];
    
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
    [self loadData];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateGuides];
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
    [imageView sd_cancelCurrentImageLoad];
    UILabel *title = (UILabel *)[cell viewWithTag:GuideCellTitleTag];
    title.text = p.title;
    title.textAlignment = NSTextAlignmentNatural;
    [imageView sd_setImageWithURL:[NSURL URLWithString:p.iconURL]
                 placeholderImage:[UIImage inat_defaultGuideImage]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"GuideDetailSegue" sender:self];
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    self.lastLocation = newLocation;
    if (!self.nearbyGuidesSyncedAt &&
        [RKClient sharedClient].reachabilityObserver.isReachabilityDetermined &&
        [RKClient sharedClient].reachabilityObserver.isNetworkReachable) {
        
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
        [self showSignupPrompt];
    } else {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Whoops!",nil)
                                                     message:[NSString stringWithFormat:NSLocalizedString(@"Looks like there was an error: %@",nil), errorMsg]
                                                    delegate:nil
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
        [av show];
    }
    }

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects {
    NSDate *now = [NSDate date];
    for (INatModel *o in objects) {
        Guide *g = (Guide *)o;
        [g setSyncedAt:now];
    }
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"syncedAt < %@ AND ngzDownloadedAt == nil",
                         now];
    
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
    [self loadData];
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
        [self showSignupPrompt];
    } else if (errorMsg) {
        [self syncFinished];
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Whoops!",nil)
                                                     message:[NSString stringWithFormat:NSLocalizedString(@"Looks like there was an error: %@",nil), errorMsg]
                                                    delegate:nil
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
        [av show];
    }
}

@end
