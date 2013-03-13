//
//  ProjectDetailViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/14/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "ProjectListViewController.h"
#import "Observation.h"
#import "Project.h"
#import "ProjectObservation.h"
#import "List.h"
#import "ListedTaxon.h"
#import "Taxon.h"
#import "ImageStore.h"
#import "DejalActivityView.h"
#import "TaxonDetailViewController.h"
#import "ProjectDetailViewController.h"

static const int ListedTaxonCellImageTag = 1;
static const int ListedTaxonCellTitleTag = 2;
static const int ListedTaxonCellSubtitleTag = 3;

@implementation ProjectListViewController
@synthesize project = _project;
@synthesize projectUser = _projectUser;
@synthesize listedTaxa = _listedTaxa;
@synthesize projectIcon = _projectIcon;
@synthesize projectTitle = _projectTitle;
@synthesize projectSubtitle = _projectSubtitle;
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
    [self performSegueWithIdentifier:@"AddObservationSegue" sender:lt];
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
    [DejalBezelActivityView activityViewForView:self.tableView
                                      withLabel:NSLocalizedString(@"Syncing list...",nil)];
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:[NSString stringWithFormat:@"/lists/%d.json", self.project.listID.intValue] 
                                                      delegate:self];
}

- (void)stopSync
{
    self.navigationItem.rightBarButtonItem = self.syncButton;
    self.tableView.scrollEnabled = YES;
    [DejalBezelActivityView removeView];
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
    if ([segue.identifier isEqualToString:@"AddObservationSegue"] || [segue.identifier isEqualToString:@"AddObservationRowSegue"]) {
        ObservationDetailViewController *vc = [segue destinationViewController];
        [vc setDelegate:self];
        Observation *o = [Observation object];
        ProjectObservation *po = [ProjectObservation object];
        po.observation = o;
        po.project = self.project;
        o.localObservedOn = [NSDate date];
        if ([sender isKindOfClass:ListedTaxon.class]) {
            ListedTaxon *lt = sender;
            o.taxon = lt.taxon;
            o.speciesGuess = lt.taxonDefaultName;
        }
        [vc setObservation:o];
    } else if ([segue.identifier isEqualToString:@"SciTaxonSegue"] || [segue.identifier isEqualToString:@"ComTaxonSegue"]) {
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
    self.projectIcon.defaultImage = [UIImage imageNamed:@"projects.png"];
    self.projectIcon.urlPath = self.project.iconURL;
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
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self stopSync];
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload {
    [self setProjectIcon:nil];
    [self setProjectTitle:nil];
    [self setProjectSubtitle:nil];
    [self setSyncButton:nil];
    [super viewDidUnload];
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
    
    TTImageView *imageView = (TTImageView *)[cell viewWithTag:ListedTaxonCellImageTag];
    [imageView unsetImage];
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:ListedTaxonCellTitleTag];
    if (lt) {
        titleLabel.text = lt.taxonDefaultName;
    }
    imageView.defaultImage = [[ImageStore sharedImageStore] iconicTaxonImageForName:(lt ? lt.iconicTaxonName : @"unknown")];
    imageView.urlPath = lt ? lt.photoURL : nil;
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
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Whoops!",nil)
                                                 message:[NSString stringWithFormat:NSLocalizedString(@"Looks like there was an error: %@",nil), errorMsg]
                                                delegate:self 
                                       cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                       otherButtonTitles:nil];
    [av show];
}

#pragma mark - ObservationDetailViewControllerDelegate
- (void)observationDetailViewControllerDidSave:(ObservationDetailViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [[self navigationController] popToViewController:self animated:YES];
}

- (void)observationDetailViewControllerDidCancel:(ObservationDetailViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [[self navigationController] popToViewController:self animated:YES];
}
@end
