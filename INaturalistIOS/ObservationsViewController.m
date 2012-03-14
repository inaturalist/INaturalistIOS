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
#import "DejalActivityView.h"
#import "ImageStore.h"

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
@synthesize loader = _loader;
@synthesize noContentLabel = _noContentLabel;

- (IBAction)sync:(id)sender {
    [RKObjectManager sharedManager].client.authenticationType = RKRequestAuthenticationTypeHTTPBasic;
    
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
    
    if (self.observationsToSyncCount > 0) {
        [self syncObservations];
    } else {
        [self syncObservationPhotos];
    }
}

- (void)stopSync
{
    if (syncActivityView) {
        [DejalBezelActivityView removeView];
        syncActivityView = nil;
    }
    
    [[[[RKObjectManager sharedManager] client] requestQueue] cancelAllRequests];
    [[self tableView] reloadData];
    [self checkSyncStatus];
    
    // sleep is ok now
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void)syncObservations
{
    NSArray *observationsToSync = [Observation needingSync];
    
    if (observationsToSync.count == 0) {
        [self stopSync];
        return;
    }
    
    // make sure the app doesn't sleep while syncing
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    NSString *activityMsg = [NSString stringWithFormat:@"Syncing 1 of %d observations", observationsToSync.count];
    if (syncActivityView) {
        [[syncActivityView activityLabel] setText:activityMsg];
    } else {
        syncActivityView = [DejalBezelActivityView activityViewForView:self.view
                                                             withLabel:activityMsg];
    }
    
    // manually applying mappings b/c PUT and POST responses return JSON without a root element, 
    // e.g. {foo: 'bar'} instead of observation: {foo: 'bar'}, which RestKit apparently can't 
    // deal with using the name of the model it just posted.
    for (Observation *o in observationsToSync) {
        if (o.syncedAt) {
            [[RKObjectManager sharedManager] putObject:o mapResponseWith:[Observation mapping] delegate:self];
        } else {
            [[RKObjectManager sharedManager] postObject:o mapResponseWith:[Observation mapping] delegate:self];
        }
    }
}

- (void)syncObservationPhotos
{
    NSArray *observationPhotosToSync = [ObservationPhoto needingSync];
    
    if (observationPhotosToSync.count == 0) {
        [self stopSync];
        return;
    }
    
    // make sure the app doesn't sleep while syncing
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    NSString *activityMsg = [NSString stringWithFormat:@"Syncing 1 of %d photos", observationPhotosToSync.count];
    if (syncActivityView) {
        [[syncActivityView activityLabel] setText:activityMsg];
    } else {
        syncActivityView = [DejalBezelActivityView activityViewForView:self.view
                                                             withLabel:activityMsg];
    }
    
    for (ObservationPhoto *op in observationPhotosToSync) {
        if (op.syncedAt) {
            [[RKObjectManager sharedManager] putObject:op mapResponseWith:[ObservationPhoto mapping] delegate:self];
        } else {
            [[RKObjectManager sharedManager] postObject:op delegate:self block:^(RKObjectLoader *loader) {
                RKObjectMapping* serializationMapping = [[[RKObjectManager sharedManager] mappingProvider] serializationMappingForClass:[ObservationPhoto class]];
                NSError* error = nil;
                NSDictionary* dictionary = [[RKObjectSerializer serializerWithObject:op mapping:serializationMapping] serializedObject:&error];
                RKParams* params = [RKParams paramsWithDictionary:dictionary];
                [params setFile:[[ImageStore sharedImageStore] pathForKey:op.photoKey 
                                                                  forSize:ImageStoreLargeSize] 
                       forParam:@"file"];
                loader.params = params;
                loader.objectMapping = [ObservationPhoto mapping];
            }];
        }
    }
}

- (IBAction)edit:(id)sender {
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
    [self checkSyncStatus];
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
        if (self.noContentLabel) {
            self.noContentLabel.hidden = NO;
        } else {
            self.noContentLabel = [[UILabel alloc] init];
            self.noContentLabel.text = @"You don't have any observations yet.";
            self.noContentLabel.backgroundColor = [UIColor whiteColor];
            self.noContentLabel.textColor = [UIColor grayColor];
            self.noContentLabel.numberOfLines = 0;
            [self.noContentLabel sizeToFit];
            self.noContentLabel.textAlignment = UITextAlignmentCenter;
            self.noContentLabel.bounds = CGRectMake(self.noContentLabel.bounds.origin.x + 20, 
                                                    self.noContentLabel.bounds.origin.y + 20, 
                                                    self.view.bounds.size.width, 
                                                    self.noContentLabel.bounds.size.height + 20);
            self.noContentLabel.center = CGPointMake(self.view.center.x, 
                                                     self.navigationController.view.center.y - self.navigationController.navigationBar.bounds.size.height - 10);
            [self.view addSubview:self.noContentLabel];
        }
    } else if (self.noContentLabel) {
        self.noContentLabel.hidden = YES;
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
        [self checkSyncStatus];
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
	// Do any additional setup after loading the view, typically from a nib.
    if (!self.observations) {
        [self loadData];
        
//        NSDate *now = [NSDate date];
//        for (Observation *o in self.observations) {
//            o.localUpdatedAt = now;
//        }
//        [[[RKObjectManager sharedManager] objectStore] save];
    }
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"header-logo.png"]];
    
    [[[[RKObjectManager sharedManager] client] requestQueue] setDelegate:self]; // TODO, might have to unset this when this view closes?
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(handleNSManagedObjectContextDidSaveNotification:) 
                                                 name:NSManagedObjectContextDidSaveNotification 
                                               object:[Observation managedObjectContext]];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
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
    [self checkSyncStatus];
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
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
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

# pragma mark INObservationDetailViewControllerDelegate methods
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

#pragma mark LoginControllerViewDelegate methods
- (void)loginViewControllerDidLogIn:(LoginViewController *)controller
{
    [self sync:nil];
}

#pragma mark RKObjectLoaderDelegate methods
- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects {
    if (objects.count == 0) return;
    
    NSDate *now = [NSDate date];
    for (INatModel *o in objects) {
        [o setSyncedAt:now];
    }
    [[[RKObjectManager sharedManager] objectStore] save];
    
    NSString *activityMsg;
    if ([[objects firstObject] isKindOfClass:[Observation class]]) {
        self.syncedObservationsCount += 1;
        activityMsg = [NSString stringWithFormat:@"Syncing %d of %d observations", 
                       self.syncedObservationsCount + 1, 
                       self.observationsToSyncCount];
        if (self.syncedObservationsCount >= self.observationsToSyncCount) {
            [self syncObservationPhotos];
        } else if (syncActivityView) {
            [[syncActivityView activityLabel] setText:activityMsg];
        }
    } else {
        self.syncedObservationPhotosCount += 1;
        activityMsg = [NSString stringWithFormat:@"Syncing %d of %d photos", 
                       self.syncedObservationPhotosCount + 1, 
                       self.observationPhotosToSyncCount];
        if (syncActivityView) {
            [[syncActivityView activityLabel] setText:activityMsg];
        }
    }
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
            errorMsg = @"Unprocessable entity";
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
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Whoops!" 
                                                     message:[NSString stringWithFormat:@"Looks like there was an error: %@", errorMsg]
                                                    delegate:self 
                                           cancelButtonTitle:@"OK" 
                                           otherButtonTitles:nil];
        [av show];
    }
}

- (void)objectLoaderDidLoadUnexpectedResponse:(RKObjectLoader *)objectLoader
{
    [self stopSync];
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Whoops!" 
                                                 message:@"Unknown error! Please report this to help@inaturalist.org"
                                                delegate:self 
                                       cancelButtonTitle:@"OK" 
                                       otherButtonTitles:nil];
    [av show];
}

#pragma mark RKRequestQueueDelegate methods
- (void)requestQueueDidFinishLoading:(RKRequestQueue *)queue
{
    [self stopSync];
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

@end
