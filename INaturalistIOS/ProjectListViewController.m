//
//  ProjectDetailViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/14/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <FontAwesomeKit/FAKIonIcons.h>

#import "ProjectListViewController.h"
#import "Observation.h"
#import "Project.h"
#import "ProjectObservation.h"
#import "List.h"
#import "ListedTaxon.h"
#import "Taxon.h"
#import "ImageStore.h"
#import "TaxonDetailViewController.h"
#import "ProjectDetailViewController.h"
#import "Analytics.h"
#import "INatUITabBarController.h"
#import "UIImage+INaturalist.h"

static const int ListedTaxonCellImageTag = 1;
static const int ListedTaxonCellTitleTag = 2;
static const int ListedTaxonCellSubtitleTag = 3;

@implementation ProjectListViewController
@synthesize project = _project;
@synthesize projectUser = _projectUser;
@synthesize listedTaxa = _listedTaxa;
@synthesize projectIcon = _projectIcon;
@synthesize projectTitle = _projectTitle;
@synthesize loader = _loader;
@synthesize lastSyncedAt = _lastSyncedAt;
@synthesize syncButton = _syncButton;
@synthesize stopSyncButton = _stopSyncButton;
@synthesize detailsPresented = _detailsPresented;

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
    
    if (self.tableView.scrollEnabled) {
        [self sync];
    } else {
        [self stopSync];
    }
}

- (void)clickedAdd:(id)sender event:(UIEvent *)event
{
    CGPoint currentTouchPosition = [event.allTouches.anyObject locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:currentTouchPosition];
    ListedTaxon *lt;
    
    if (self.project.observationsRestrictedToList) {
        lt = [self.listedTaxa objectAtIndex:indexPath.row];
    } else {
        if (indexPath.row == 0) {
            lt = nil;
        } else {
            lt = [self.listedTaxa objectAtIndex:indexPath.row-1];
        }
    }
    
    // be defensive
    if (self.tabBarController && [self.tabBarController respondsToSelector:@selector(triggerNewObservationFlowForTaxon:project:)]) {
        [[Analytics sharedClient] event:kAnalyticsEventNewObservationStart withProperties:@{ @"From": @"ProjectList" }];
        [((INatUITabBarController *)self.tabBarController) triggerNewObservationFlowForTaxon:lt.taxon
                                                                                     project:self.project];
    } else if (self.presentingViewController && [self.presentingViewController respondsToSelector:@selector(triggerNewObservationFlowForTaxon:project:)]) {
        // can't present from the tab bar while it's out of the view hierarchy
        // so dismiss the presented view (ie the parent of this taxon details VC)
        // and then trigger the new observation flow once the tab bar is back
        // in thei heirarchy.
        INatUITabBarController *tabBar = (INatUITabBarController *)self.presentingViewController;
        [tabBar dismissViewControllerAnimated:YES
                                   completion:^{
                                       [[Analytics sharedClient] event:kAnalyticsEventNewObservationStart
                                                        withProperties:@{ @"From": @"ProjectList" }];
                                       [tabBar triggerNewObservationFlowForTaxon:lt.taxon
                                                                         project:self.project];
                                   }];
    }
}

- (void)sync
{
    if (!self.stopSyncButton) {
        self.stopSyncButton = [[UIBarButtonItem alloc]
                               initWithBarButtonSystemItem:UIBarButtonSystemItemStop 
                               target:self 
                               action:@selector(stopSync)];
    }
    self.navigationItem.rightBarButtonItem = self.stopSyncButton;
    self.lastSyncedAt = [NSDate date];
    self.tableView.scrollEnabled = NO;
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Syncing list...",nil)];
    NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSString *url =[NSString stringWithFormat:@"/lists/%d.json?locale=%@-%@", self.project.listID.intValue, language, countryCode   ];
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:url delegate:self];
}

- (void)stopSync
{
    self.navigationItem.rightBarButtonItem = self.syncButton;
    self.tableView.scrollEnabled = YES;
    [SVProgressHUD dismiss];
    [[[[RKObjectManager sharedManager] client] requestQueue] cancelAllRequests];
    [self loadData];
    [[self tableView] reloadData];
}

- (void)loadData
{
    NSArray *sorts = [NSArray arrayWithObjects:
                      [[NSSortDescriptor alloc] initWithKey:@"ancestry" ascending:YES], 
                      [[NSSortDescriptor alloc] initWithKey:@"recordID" ascending:YES], 
                      nil];
    self.listedTaxa = [NSMutableArray arrayWithArray:
                       [self.project.projectList.listedTaxa.allObjects sortedArrayUsingDescriptors:sorts]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"SciTaxonSegue"] || [segue.identifier isEqualToString:@"ComTaxonSegue"]) {
        NSInteger row = [[self.tableView indexPathForSelectedRow] row];
        if (!self.project.observationsRestrictedToList) {
            row -= 1;
        }
        TaxonDetailViewController *vc = [segue destinationViewController];
        ListedTaxon *lt = [self.listedTaxa objectAtIndex:row];
        if (lt) vc.taxon = lt.taxon;
    } else if ([segue.identifier isEqualToString:@"ProjectDetailSegue"]) {
        ProjectDetailViewController *vc = (ProjectDetailViewController *)[segue.destinationViewController topViewController];
        vc.project = self.project;
        self.detailsPresented = YES;
    } 
}

#pragma mark - lifecycle
- (void)viewDidLoad
{
    if (self.project) {
        self.projectUser = [ProjectUser objectWithPredicate:[NSPredicate predicateWithFormat:@"projectID = %@", self.project.recordID]];
    }
    if (!self.listedTaxa) {
        [self loadData];
    }
    
    [self.projectIcon sd_setImageWithURL:[NSURL URLWithString:self.project.iconURL]
                        placeholderImage:[UIImage inat_defaultProjectImage]];
    self.projectTitle.text = self.project.title;
    
    CAGradientLayer *lyr = [CAGradientLayer layer];
    lyr.colors = [NSArray arrayWithObjects:
                  (id)[UIColor whiteColor].CGColor, 
                  (id)[UIColor colorWithRed:(220/255.0)  green:(220/255.0)  blue:(220/255.0)  alpha:1.0].CGColor, nil];
    lyr.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0], [NSNumber numberWithFloat:1], nil];
    lyr.frame = self.tableView.tableHeaderView.bounds;
    [self.tableView.tableHeaderView.layer insertSublayer:lyr atIndex:0];
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:YES];
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.projectUser && !self.detailsPresented) {
        [self performSegueWithIdentifier:@"ProjectDetailSegue" sender:nil];
    } else if (self.listedTaxa.count == 0 && !self.lastSyncedAt && [[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        [self sync];
    }
    
    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateProjectList];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateProjectList];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self stopSync];
    [super viewWillDisappear:animated];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.project.observationsRestrictedToList) {
        return self.listedTaxa.count;
    } else {
        return self.listedTaxa.count + 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ListedTaxon *lt;
    NSString *cellIdentifier;
    NSInteger row = self.project.observationsRestrictedToList ? indexPath.row : (indexPath.row - 1);
    if (!self.project.observationsRestrictedToList && indexPath.row == 0) {
        lt = nil;
        cellIdentifier = @"AddObservationCell";
    } else {
        lt = [self.listedTaxa objectAtIndex:row];
        cellIdentifier = [lt.taxonName isEqualToString:lt.taxonDefaultName] ? @"ListedTaxonOneNameCell" : @"ListedTaxonTwoNamesCell";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    UIButton *addButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 35)];
    [addButton setBackgroundImage:[UIImage imageNamed:@"add_button"] 
                         forState:UIControlStateNormal];
    [addButton setBackgroundImage:[UIImage imageNamed:@"add_button_highlight"] 
                         forState:UIControlStateHighlighted];
    [addButton setTitle:NSLocalizedString(@"Add",nil) forState:UIControlStateNormal];
    [addButton setTitle:NSLocalizedString(@"Add",nil) forState:UIControlStateHighlighted];
    addButton.titleLabel.textColor = [UIColor whiteColor];
    addButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [addButton addTarget:self action:@selector(clickedAdd:event:) forControlEvents:UIControlEventTouchUpInside];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.accessoryView = addButton;
    
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:ListedTaxonCellImageTag];
    [imageView sd_cancelCurrentImageLoad];
        UILabel *titleLabel = (UILabel *)[cell viewWithTag:ListedTaxonCellTitleTag];
    if (lt) {
        titleLabel.text = lt.taxonDefaultName;
    }
    
    UIImage *iconicTaxonImage = [[ImageStore sharedImageStore] iconicTaxonImageForName:(lt ? lt.iconicTaxonName : @"unknown")];
    imageView.image = iconicTaxonImage;
    if (lt) {
        [imageView sd_setImageWithURL:[NSURL URLWithString:lt.photoURL]
                     placeholderImage:iconicTaxonImage];
    }

    if (lt) {
        if ([lt.taxonName isEqualToString:lt.taxonDefaultName]) {
            if (lt.taxon.rankLevel.intValue >= 30) {
                titleLabel.font = [UIFont boldSystemFontOfSize:titleLabel.font.pointSize];
            } else {
                titleLabel.font = [UIFont fontWithName:@"Helvetica-BoldOblique" size:titleLabel.font.pointSize];
            }
        } else {
            UILabel *subtitleLabel = (UILabel *)[cell viewWithTag:ListedTaxonCellSubtitleTag];
            subtitleLabel.text = lt.taxonName;
        }
    } else {
        titleLabel.font = [UIFont boldSystemFontOfSize:titleLabel.font.pointSize];
    }
    
    return cell;
}

#pragma mark - RKObjectLoaderDelegate
- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects
{
    [self stopSync];
    if (objects.count == 0) return;
    NSDate *now = [NSDate date];
    for (INatModel *o in objects) {
        [o setSyncedAt:now];
    }
    
    NSArray *rejects = [ListedTaxon objectsWithPredicate:
                        [NSPredicate predicateWithFormat:@"listID = %d AND syncedAt < %@", 
                         self.project.listID.intValue, now]];
    for (ListedTaxon *lt in rejects) {
        [lt deleteEntity];
    }
    
    NSError *error = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    // was running into a bug in release build config where the object loader was 
    // getting deallocated after handling an error.  This is a kludge.
    self.loader = objectLoader;
    
    [self stopSync];
    NSString *errorMsg;
    bool jsonParsingError = false, authFailure = false;
    switch (objectLoader.response.statusCode) {
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
    
    [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:NSLocalizedString(@"Looks like there was an error: %@",nil), errorMsg]];
}

@end
