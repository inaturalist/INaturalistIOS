//
//  GuidesViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/1/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <Three20/Three20.h>
#import "GuidesViewController.h"
#import "Guide.h"
#import "GuideDetailViewController.h"
#import "GuideContainerViewController.h"

static const int GuideCellImageTag = 1;
static const int GuideCellTitleTag = 2;
static const int ListControlIndexAll = 0;
static const int ListControlIndexUser = 1;
static const int ListControlIndexNearby = 2;

@implementation GuidesViewController
@synthesize guides = _guides;
@synthesize loader = _loader;
@synthesize guideUsersSyncedAt = _lastSyncedAt;
//@synthesize featuredGuidesSyncedAt = _featuredGuidesSyncedAt;
@synthesize allGuidesSyncedAt = _allGuidesSyncedAt;
@synthesize nearbyGuidesSyncedAt = _nearbyGuidesSyncedAt;
@synthesize noContentLabel = _noContentLabel;
@synthesize guidesSearchController = _guidesSearchController;
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
    
    if (syncNeeded && [[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        [self sync];
    } else {
        [self stopSync];
    }
}

- (void)loadAllGuides
{
    self.guides = [NSMutableArray arrayWithArray:Guide.all];
}

- (void)loadUserGuides
{
//    NSArray *guideUsers = [GuideUser.all sortedArrayUsingComparator:^NSComparisonResult(GuideUser *obj1, GuideUser *obj2) {
//        return [obj1.guide.title.lowercaseString compare:obj2.guide.title.lowercaseString];
//    }];
//    self.guides = [NSMutableArray arrayWithArray:[guideUsers valueForKey:@"guide"]];
    self.guides = [NSMutableArray arrayWithArray:Guide.all];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *username = [defaults objectForKey:INatUsernamePrefKey];
//    self.guides = [NSMutableArray arrayWithArray:[Guide findByAttribute:@"userLogin" withValue:username]];
    self.guides = [NSMutableArray arrayWithArray:[Guide objectsWithPredicate:[NSPredicate predicateWithFormat:@"userLogin = %@", username]]];
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
    NSArray *guides = [Guide objectsWithFetchRequest:request];
    self.guides = [NSMutableArray arrayWithArray:[guides sortedArrayUsingComparator:^NSComparisonResult(Guide *p1, Guide *p2) {
        CLLocation *p1Location = [[CLLocation alloc] initWithLatitude:p1.latitude.doubleValue
                                                            longitude:p1.longitude.doubleValue];
        CLLocation *p2Location = [[CLLocation alloc] initWithLatitude:p2.latitude.doubleValue
                                                            longitude:p2.longitude.doubleValue];
        NSNumber *p1Distance = [NSNumber numberWithDouble:[self.lastLocation distanceFromLocation:p1Location]];
        NSNumber *p2Distance = [NSNumber numberWithDouble:[self.lastLocation distanceFromLocation:p2Location]];
        return [p1Distance compare:p2Distance];
    }]];
    [self.guides filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(Guide *p, NSDictionary *bindings) {
        CLLocation *loc = [[CLLocation alloc] initWithLatitude:p.latitude.doubleValue
                                                     longitude:p.longitude.doubleValue];
        NSNumber *d = [NSNumber numberWithDouble:[self.lastLocation distanceFromLocation:loc]];
        return d.doubleValue < 500000; // meters
    }]];
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
    [self sync:YES];
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
            self.noContentLabel.textAlignment = UITextAlignmentCenter;
            self.noContentLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        }
        
        if (self.listControl.selectedSegmentIndex == ListControlIndexNearby) {
            self.noContentLabel.text = NSLocalizedString(@"No nearby guides.",nil);
        } else {
            self.noContentLabel.text = NSLocalizedString(@"You haven't joined any guides yet.",nil);
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
            [self syncUserGuides];
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
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:url
                                                 objectMapping:[Guide mapping]
                                                      delegate:self];
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
        [self stopSync];
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
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:url
                                                 objectMapping:[Guide mapping]
                                                      delegate:self];
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
//        [[RKObjectManager sharedManager] loadObjectsAtResourcePath:url
//                                                     objectMapping:[GuideUser mapping]
//                                                          delegate:self];
        [[RKObjectManager sharedManager] loadObjectsAtResourcePath:url
                                                     objectMapping:[Guide mapping]
                                                          delegate:self];
    } else {
        [self stopSync];
        [self performSegueWithIdentifier:@"LoginSegue" sender:self];
    }
    self.guideUsersSyncedAt = [NSDate date];
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
        _listControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:NSLocalizedString(@"All",nil), NSLocalizedString(@"Your Guides",nil), NSLocalizedString(@"Nearby",nil),nil]];
        _listControl.segmentedControlStyle = UISegmentedControlStyleBar;
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        //NSString *username = [defaults objectForKey:INatUsernamePrefKey];
        NSString *inatToken = [defaults objectForKey:INatTokenPrefKey];
        _listControl.selectedSegmentIndex = (inatToken && inatToken.length > 0) ? ListControlIndexUser : ListControlIndexNearby;
        
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"GuideDetailSegue"]) {
        GuideContainerViewController *vc = [segue destinationViewController];
        if ([sender isKindOfClass:Guide.class]) {
            [vc setGuide:sender];
        } else {
            Guide *g = [self.guides
                          objectAtIndex:[[self.tableView
                                          indexPathForSelectedRow] row]];
            [vc setGuide:g];
        }
    } else if ([segue.identifier isEqualToString:@"LoginSegue"]) {
        LoginViewController *vc = (LoginViewController *)[segue.destinationViewController topViewController];
        vc.delegate = self;
    }
}

#pragma mark - View lifecycle

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
        self.locationManager.delegate = self;
        self.locationManager.distanceFilter = 1000;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableView deselectRowAtIndexPath:[self.tableView.indexPathsForSelectedRows objectAtIndex:0] animated:YES];
    
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
    TTImageView *imageView = (TTImageView *)[cell viewWithTag:GuideCellImageTag];
    [imageView unsetImage];
    UILabel *title = (UILabel *)[cell viewWithTag:GuideCellTitleTag];
    title.text = p.title;
    imageView.defaultImage = [UIImage imageNamed:@"guides"];
    imageView.urlPath = p.iconURL;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"GuideDetailSegue" sender:self];
}

#pragma mark - RKObjectLoaderDelegate
- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects
{
    NSDate *now = [NSDate date];
    for (INatModel *o in objects) {
        Guide *g = (Guide *)o;
        [o setSyncedAt:now];
    }
    
//    if ([objectLoader.resourcePath rangeOfString:@"guides/user"].location != NSNotFound) {
//        NSArray *rejects = [GuideUser objectsWithPredicate:[NSPredicate predicateWithFormat:@"syncedAt < %@", now]];
//        for (GuideUser *pu in rejects) {
//            [pu deleteEntity];
//        }
//    }
    
    NSError *error = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
    
    [self stopSync];
    [self loadData];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    // was running into a bug in release build config where the object loader was
    // getting deallocated after handling an error.  This is a kludge.
    self.loader = objectLoader;
    
    [self stopSync];
    NSString *errorMsg;
    bool jsonParsingError = false, authFailure = false;
    switch (objectLoader.response.statusCode) {
            // Unauthorized
        case 401:
            authFailure = true;
            // UNPROCESSABLE ENTITY
        case 422:
            errorMsg = NSLocalizedString(@"Unprocessable entity",nil);
            break;
        default:
            // KLUDGE!! RestKit doesn't seem to handle failed auth very well
            jsonParsingError = [error.domain isEqualToString:@"JKErrorDomain"] && error.code == -1;
            authFailure = [error.domain isEqualToString:@"NSURLErrorDomain"] && error.code == -1012;
            errorMsg = error.localizedDescription;
    }
    
    if (jsonParsingError || authFailure) {
        [self performSegueWithIdentifier:@"LoginSegue" sender:self];
    } else {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Whoops!",nil)
                                                     message:[NSString stringWithFormat:NSLocalizedString(@"Looks like there was an error: %@",nil), errorMsg]
                                                    delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
        [av show];
    }
}

#pragma mark - LoginViewControllerDelegate
- (void)loginViewControllerDidLogIn:(LoginViewController *)controller
{
    self.guideUsersSyncedAt = nil;
    [self sync];
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    self.lastLocation = newLocation;
    if (!self.nearbyGuidesSyncedAt) {
        [self syncNearbyGuides];
    }
}

- (void)viewDidUnload {
    [self setSyncButton:nil];
    [self setSyncActivityItem:nil];
    [super viewDidUnload];
}
@end
