//
//  ObservationsViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "ObservationsViewController.h"
#import "LoginViewController.h"
#import "Observation.h"
#import "ObservationPhoto.h"
#import "ProjectObservation.h"
#import "Project.h"
#import "DejalActivityView.h"
#import "ImageStore.h"
#import "INatUITabBarController.h"
#import "INaturalistAppDelegate.h"

static int DeleteAllAlertViewTag = 0;
static const int ObservationCellImageTag = 5;
static const int ObservationCellTitleTag = 1;
static const int ObservationCellSubTitleTag = 2;
static const int ObservationCellUpperRightTag = 3;
static const int ObservationCellLowerRightTag = 4;

@implementation ObservationsViewController
@synthesize syncButton;
@synthesize observations = _observations;
@synthesize observationsToSyncCount = _observationsToSyncCount;
@synthesize observationPhotosToSyncCount = _observationPhotosToSyncCount;
@synthesize syncToolbarItems = _syncToolbarItems;
@synthesize syncedObservationsCount = _syncedObservationsCount;
@synthesize syncedObservationPhotosCount = _syncedObservationPhotosCount;
@synthesize deleteAllButton = _deleteAllButton;
@synthesize editButton = _editButton;
@synthesize stopSyncButton = _stopSyncButton;
@synthesize noContentLabel = _noContentLabel;
@synthesize syncQueue = _syncQueue;
@synthesize syncErrors = _syncErrors;

- (IBAction)sync:(id)sender {
    if (self.isSyncing) {
        return;
    }
    
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Internet connection required" 
                                                     message:@"You must be connected to the Internet to sync with iNaturalist.org"
                                                    delegate:self 
                                           cancelButtonTitle:@"OK" 
                                           otherButtonTitles:nil];
        [av show];
        return;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:INatUsernamePrefKey]) {
        [self performSegueWithIdentifier:@"LoginSegue" sender:nil];
        return;
    }
    
    if (!self.stopSyncButton) {
        self.stopSyncButton = [[UIBarButtonItem alloc] initWithTitle:@"Stop sync" 
                                                               style:UIBarButtonItemStyleBordered 
                                                              target:self 
                                                              action:@selector(stopSync)];
        self.stopSyncButton.tintColor = [UIColor redColor];
    }
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self.navigationController setToolbarHidden:NO];
    [self setToolbarItems:[NSArray arrayWithObjects:flex, self.stopSyncButton, flex, nil] 
                 animated:YES];
    
    NSString *activityMsg = @"Syncing...";
    if (syncActivityView) {
        [[syncActivityView activityLabel] setText:activityMsg];
    } else {
        self.tableView.scrollEnabled = NO;
        syncActivityView = [DejalBezelActivityView activityViewForView:self.tableView
                                                             withLabel:activityMsg];
    }
    
    self.syncQueue = [[SyncQueue alloc] initWithDelegate:self];
    [self.syncQueue addModel:Observation.class];
    [self.syncQueue addModel:ProjectObservation.class];
    [self.syncQueue addModel:ObservationPhoto.class syncSelector:@selector(syncObservationPhoto:)];
    [self.syncQueue start];
}

- (void)stopSync
{
    if (syncActivityView) {
        [DejalBezelActivityView removeView];
        syncActivityView = nil;
    }
    
    if (self.syncQueue) {
        [self.syncQueue stop];
    }
    [[self tableView] reloadData];
    
    self.tableView.scrollEnabled = YES;
    
    [self checkSyncStatus];
}

- (BOOL)isSyncing
{
    return [UIApplication sharedApplication].isIdleTimerDisabled;
}

- (void)syncObservationPhoto:(ObservationPhoto *)op
{
    INaturalistAppDelegate *app = [[UIApplication sharedApplication] delegate];
    app.photoObjectManager.client.authenticationType = RKRequestAuthenticationTypeHTTPBasic;
    if (op.syncedAt) {
        [app.photoObjectManager putObject:op mapResponseWith:[ObservationPhoto mapping] delegate:self.syncQueue];
    } else {
        [app.photoObjectManager postObject:op delegate:self.syncQueue block:^(RKObjectLoader *loader) {
            RKObjectMapping* serializationMapping = [app.photoObjectManager.mappingProvider 
                                                     serializationMappingForClass:[ObservationPhoto class]];
            NSError* error = nil;
            NSDictionary* dictionary = [[RKObjectSerializer serializerWithObject:op mapping:serializationMapping] 
                                        serializedObject:&error];
            RKParams* params = [RKParams paramsWithDictionary:dictionary];
            NSInteger imageSize = [[[RKClient sharedClient] reachabilityObserver] isReachableViaWiFi] ? ImageStoreLargeSize : ImageStoreSmallSize;
            [params setFile:[[ImageStore sharedImageStore] pathForKey:op.photoKey 
                                                              forSize:imageSize] 
                   forParam:@"file"];
            loader.params = params;
            loader.objectMapping = [ObservationPhoto mapping];
        }];
    }
}

- (IBAction)edit:(id)sender {
    if (self.isSyncing) {
        [self stopSync];
    }
    if ([self isEditing]) {
        [self stopEditing];
    } else {
        [sender setTitle:@"Done"];
        [(UIBarButtonItem *)sender setStyle:UIBarButtonItemStyleDone];
        [self setEditing:YES animated:YES];
        UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        if (!self.deleteAllButton) {
            self.deleteAllButton = [[UIBarButtonItem alloc] initWithTitle:@"Delete all" 
                                                                    style:UIBarButtonItemStyleDone 
                                                                   target:self 
                                                                   action:@selector(clickedDeleteAll)];
            self.deleteAllButton.tintColor = [UIColor redColor];
        }
        [self setToolbarItems:[NSArray arrayWithObjects:flex, self.deleteAllButton, flex, nil] animated:YES];
        [self.navigationController setToolbarHidden:NO animated:YES];
    }
}

- (void)stopEditing
{
    [self.editButton setTitle:@"Edit"];
    [self.editButton setStyle:UIBarButtonItemStyleBordered];
    [self setEditing:NO animated:YES];
    [self checkSyncStatus];
}

- (void)clickedDeleteAll
{
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Are you sure" 
                                                 message:@"This will delete all the observations on this device, but you need to go to iNaturalist.org to delete them from the website." 
                                                delegate:self 
                                       cancelButtonTitle:@"Cancel" 
                                       otherButtonTitles:@"Delete all", nil];
    av.tag = DeleteAllAlertViewTag;
    [av show];
}

- (void)deleteAll
{
    // note: you'll probably want to empty self.observations and reload the 
    // tableView's data, otherwise the tableView's references to the observation 
    // objects is going to cause a problem when Core Data deletes them
    [Observation deleteAll];
    [DejalBezelActivityView removeView];
    [(INatUITabBarController *)self.tabBarController setObservationsTabBadge];
    [self stopEditing];
}

- (void)loadData
{
    [self setObservations:[[NSMutableArray alloc] initWithArray:[Observation all]]];
    [self setObservationsToSyncCount:0];
    // if/when you want to bring back loading existing data, it's pretty easy
//    if (!self.observations || [self.observations count] == 0) {
//        [[RKObjectManager sharedManager] loadObjectsAtResourcePath:@"/observations/kueda" 
//                                                     objectMapping:[Observation mapping] 
//                                                          delegate:self];
//    }
//    if (self.observations.count == 0) {
//        for (int i = 0; i < 500; i++) {
//            [self.observations addObject:[Observation stub]];
//        }
//        [[[RKObjectManager sharedManager] objectStore] save];
//    }
}

- (void)reload
{
    [self loadData];
    [[self tableView] reloadData];
}

- (void)checkSyncStatus
{
    self.observationsToSyncCount = [Observation needingSyncCount];
    self.observationPhotosToSyncCount = [ObservationPhoto needingSyncCount];
    NSMutableString *msg = [NSMutableString stringWithString:@"Sync "];
    if (self.observationsToSyncCount > 0) {
        [msg appendString:[NSString stringWithFormat:@"%d observation", self.observationsToSyncCount]];
        if (self.observationsToSyncCount > 1) [msg appendString:@"s"];
        if (self.observationPhotosToSyncCount > 0) [msg appendString:@", "];
    }
    if (self.observationPhotosToSyncCount > 0) {
        [msg appendString:[NSString stringWithFormat:@"%d photo", self.observationPhotosToSyncCount]];
        if (self.observationPhotosToSyncCount > 1) [msg appendString:@"s"];
    }
    [self.syncButton setTitle:msg];
    if (self.itemsToSyncCount > 0) {
        [self.navigationController setToolbarHidden:NO];
        [self setToolbarItems:self.syncToolbarItems animated:YES];
    } else {
        [self.navigationController setToolbarHidden:YES];
        [self setToolbarItems:nil animated:YES];
    }
    self.syncedObservationsCount = 0;
}

- (void)checkEmpty
{
    if (self.observations.count == 0) {
        if (!self.noContentLabel) {
            self.noContentLabel = [[UILabel alloc] init];
            self.noContentLabel.text = @"You don't have any observations yet.";
            self.noContentLabel.backgroundColor = [UIColor clearColor];
            self.noContentLabel.textColor = [UIColor grayColor];
            self.noContentLabel.numberOfLines = 0;
            [self.noContentLabel sizeToFit];
            self.noContentLabel.textAlignment = UITextAlignmentCenter;
            self.noContentLabel.center = CGPointMake(self.view.center.x, 
                                                     self.tableView.rowHeight * 2 + (self.tableView.rowHeight / 2));
            self.noContentLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        }
        [self.view addSubview:self.noContentLabel];
    } else if (self.noContentLabel) {
        [self.noContentLabel removeFromSuperview];
    }
}

- (int)itemsToSyncCount
{
    if (!self.observationsToSyncCount) self.observationsToSyncCount = 0;
    if (!self.observationPhotosToSyncCount) self.observationPhotosToSyncCount = 0;
    return self.observationsToSyncCount + self.observationPhotosToSyncCount;
}

- (void)handleNSManagedObjectContextDidSaveNotification:(NSNotification *)notification
{
    if (self.view && ![[UIApplication sharedApplication] isIdleTimerDisabled]) {
        [self reload];
    }
}

# pragma mark TableViewController methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.observations count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Observation *o = [self.observations objectAtIndex:[indexPath row]];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ObservationTableCell"];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:ObservationCellImageTag];
    UILabel *title = (UILabel *)[cell viewWithTag:ObservationCellTitleTag];
    UILabel *subtitle = (UILabel *)[cell viewWithTag:ObservationCellSubTitleTag];
    UILabel *upperRight = (UILabel *)[cell viewWithTag:ObservationCellUpperRightTag];
    UIImageView *syncImage = (UIImageView *)[cell viewWithTag:ObservationCellLowerRightTag];
    UIImage *img;
    if (o.sortedObservationPhotos.count > 0) {
        ObservationPhoto *op = [o.sortedObservationPhotos objectAtIndex:0];
        img = [[ImageStore sharedImageStore] find:op.photoKey forSize:ImageStoreSquareSize];
    } else {
        img = [[ImageStore sharedImageStore] iconicTaxonImageForName:o.iconicTaxonName];
    }
    [imageView setImage:img];
    if (o.speciesGuess) {
        [title setText:o.speciesGuess];
    } else {
        [title setText:@"Something..."];
    }
    
    if (o.placeGuess && o.placeGuess.length > 0) {
        subtitle.text = o.placeGuess;
    } else if (o.latitude) {
        subtitle.text = [NSString stringWithFormat:@"%@, %@", o.latitude, o.longitude];
    } else {
        subtitle.text = @"Somewhere...";
    }
    
    upperRight.text = o.observedOnShortString;
    syncImage.hidden = !o.needsSync;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Observation *o = [self.observations objectAtIndex:indexPath.row];
        [self.observations removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
        [o destroy];
        if (!self.isEditing) {
            [self checkSyncStatus];
        }
        if (self.observations.count == 0) {
            [self stopEditing];
        }
    }
}

# pragma mark memory management
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];

//    // if you need to test syncing lots of obs
//    [Observation deleteAll];
//    for (int i = 0; i < 50; i++) {
//        [self.observations addObject:[Observation stub]];
//    }
//    [[[RKObjectManager sharedManager] objectStore] save];
    
	// Do any additional setup after loading the view, typically from a nib.
    if (!self.observations) {
        [self loadData];
    }
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"header-logo.png"]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(handleNSManagedObjectContextDidSaveNotification:) 
                                                 name:NSManagedObjectContextDidSaveNotification 
                                               object:[Observation managedObjectContext]];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self reload];
    [self checkEmpty];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[[self navigationController] toolbar] setBarStyle:UIBarStyleBlack];
    [self setSyncToolbarItems:[NSArray arrayWithObjects:
                               [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                               self.syncButton, 
                               [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                               nil]];
    if (!self.isSyncing) {
        [self checkSyncStatus];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self stopSync];
    [self stopEditing];
    [self setToolbarItems:nil animated:YES];
    [self.navigationController setToolbarHidden:YES animated:YES];
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIDeviceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"AddObservationSegue"]) {
        ObservationDetailViewController *vc = [segue destinationViewController];
        [vc setDelegate:self];
        Observation *o = [Observation object];
        o.localObservedOn = [NSDate date];
        [vc setObservation:o];
    } else if ([segue.identifier isEqualToString:@"EditObservationSegue"]) {
        ObservationDetailViewController *vc = [segue destinationViewController];
        [vc setDelegate:self];
        Observation *o = [self.observations 
                          objectAtIndex:[[self.tableView 
                                          indexPathForSelectedRow] row]];
        [vc setObservation:o];
    } else if ([segue.identifier isEqualToString:@"LoginSegue"]) {
        LoginViewController *vc = (LoginViewController *)[segue.destinationViewController topViewController];
        [vc setDelegate:self];
    }
}

#pragma mark LoginControllerViewDelegate methods
- (void)loginViewControllerDidLogIn:(LoginViewController *)controller
{
    [self sync:nil];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == DeleteAllAlertViewTag && buttonIndex == 1) {
        [DejalBezelActivityView activityViewForView:self.navigationController.view
                                          withLabel:@"Deleting observations..."];
        [self.observations removeAllObjects];
        [self.tableView reloadData];
        [self performSelectorInBackground:@selector(deleteAll) withObject:nil];
    }
}

#pragma mark - SyncQueueDelegate
- (void)syncQueueStartedSyncFor:(id)model
{
    NSString *activityMsg;
    if (model == ObservationPhoto.class) {
        activityMsg = @"Syncing photos...";
    } else {
        activityMsg = [NSString stringWithFormat:@"Syncing %@...", NSStringFromClass(model).humanize.pluralize];
    }
    if (syncActivityView) {
        [[syncActivityView activityLabel] setText:activityMsg];
        [syncActivityView layoutSubviews];
    } else {
        syncActivityView = [DejalBezelActivityView activityViewForView:self.view
                                                             withLabel:activityMsg];
    }
}
- (void)syncQueueSynced:(INatModel *)record number:(NSInteger)number of:(NSInteger)total
{
    NSString *activityMsg = [NSString stringWithFormat:@"Synced %d of %d %@", 
                             number, 
                             total, 
                             NSStringFromClass(record.class).humanize.pluralize];
    if (syncActivityView) {
        [[syncActivityView activityLabel] setText:activityMsg];
        [syncActivityView layoutSubviews];
    } else {
        syncActivityView = [DejalBezelActivityView activityViewForView:self.view
                                                             withLabel:activityMsg];
    }
}

- (void)syncQueueFinished
{
    [self stopSync];
    if (self.syncErrors && self.syncErrors.count > 0) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Heads up" 
                                                     message:[self.syncErrors componentsJoinedByString:@"\n\n"]
                                                    delegate:self 
                                           cancelButtonTitle:@"OK" 
                                           otherButtonTitles:nil];
        [av show];
        self.syncErrors = nil;
    }
    
    // make sure any deleted records get gone
    [[[RKObjectManager sharedManager] objectStore] save];
}

- (void)syncQueueAuthRequired
{
    [self stopSync];
    [self performSegueWithIdentifier:@"LoginSegue" sender:nil];
}

- (void)syncQueue:(SyncQueue *)syncQueue objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error
{
    if ([objectLoader.targetObject isKindOfClass:ProjectObservation.class]) {
        ProjectObservation *po = (ProjectObservation *)objectLoader.targetObject;
        if (!self.syncErrors) {
            self.syncErrors = [[NSMutableArray alloc] init];
        }
        [self.syncErrors addObject:[NSString stringWithFormat:@"%@ (%@) couldn't be added to project %@: %@", 
                                    po.observation.speciesGuess, 
                                    po.observation.observedOnShortString,
                                    po.project.title,
                                    error.localizedDescription]];
        [po deleteEntity];
    } else {
        if ([self isSyncing]) {
            NSString *alertTitle;
            NSString *alertMessage;
            if (error.domain == RKRestKitErrorDomain && error.code == RKRequestConnectionTimeoutError) {
                alertTitle = @"Request timed out";
                alertMessage = @"This can happen when your Internet connection is slow or intermittent.  Please try again the next time you're on WiFi.";
            } else {
                alertTitle = @"Whoops!";
                alertMessage = [NSString stringWithFormat:@"Looks like there was an error: %@", error.localizedDescription];
            }
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:alertTitle 
                                                         message:alertMessage
                                                        delegate:self 
                                               cancelButtonTitle:@"OK" 
                                               otherButtonTitles:nil];
            [av show];
        } 
        [self stopSync];
    }
}

- (void)syncQueueUnexpectedResponse
{
    [self stopSync];
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Whoops!" 
                                                 message:@"There was an unexpected error."
                                                delegate:self 
                                       cancelButtonTitle:@"OK" 
                                       otherButtonTitles:nil];
    [av show];
}

@end
