//
//  INaturalistIOSViewController.m
//  INaturalistIOS
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "ObservationsViewController.h"
#import "LoginViewController.h"
#import "Observation.h"
#import "DejalActivityView.h"

@implementation ObservationsViewController
@synthesize syncLabel;
@synthesize syncButton;
@synthesize observations;
@synthesize observationsToSyncCount = _observationsToSyncCount;
@synthesize syncToolbarItems = _syncToolbarItems;
@synthesize syncedObservationsCount = _syncedObservationsCount;

- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    [[self tableView] setSeparatorColor:[UIColor lightGrayColor]];
    [[self tableView] setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    return self;
}

- (IBAction)sync:(id)sender {
    NSArray *observationsToSync = [observations filteredArrayUsingPredicate:
                                   [NSPredicate predicateWithFormat:
                                    @"syncedAt = nil OR syncedAt < localUpdatedAt"]];
    
    if (observationsToSync.count == 0) return;
    
    syncActivityView = [DejalBezelActivityView activityViewForView:self.navigationController.view
                                                         withLabel:[NSString 
                                                                    stringWithFormat:
                                                                    @"Syncing 1 of %d observations", observationsToSync.count]];
    
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

- (IBAction)edit:(id)sender {
    if ([self isEditing]) {
        [sender setTitle:@"Edit"];
        [self setEditing:NO animated:YES];
        [self checkSyncStatus];
    } else {
        [sender setTitle:@"Done"];
        [self setEditing:YES animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [[observations objectAtIndex:indexPath.row] destroy];
        [observations removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }
}

- (void)loadData
{
    [self setObservations:[[NSMutableArray alloc] initWithArray:[Observation all]]];
    [self setObservationsToSyncCount:0];
// if/when you want to bring back loading existing data, it's pretty easy
//    if (!observations || [observations count] == 0) {
//        [[RKObjectManager sharedManager] loadObjectsAtResourcePath:@"/observations/kueda" 
//                                                     objectMapping:[Observation mapping] 
//                                                          delegate:self];
//    }
    [self checkSyncStatus];
}


- (id)initWithStyle:(UITableViewStyle)style
{
    return [self init];
}

- (void)checkSyncStatus
{
    self.observationsToSyncCount = [[[self observations] filteredArrayUsingPredicate:
                                     [NSPredicate predicateWithFormat:@"syncedAt = nil OR syncedAt < localUpdatedAt"]] count];
    NSMutableString *msg = [NSMutableString stringWithFormat:@"Sync %d observation", self.observationsToSyncCount];
    if (self.observationsToSyncCount != 1) [msg appendString:@"s"];
    [syncButton setTitle:msg];
    if (self.observationsToSyncCount > 0) {
        [self.navigationController setToolbarHidden:NO];
        [self setToolbarItems:self.syncToolbarItems animated:YES];
    } else {
        [self.navigationController setToolbarHidden:YES];
        [self setToolbarItems:nil animated:YES];
    }
    self.syncedObservationsCount = 0;
}


# pragma mark TableViewController methods


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [observations count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Observation *o = [observations objectAtIndex:[indexPath row]];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ObservationTableCell"];
    [[cell textLabel] setText:[o speciesGuess]];
    return cell;
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
    [[[self navigationController] toolbar] setBarStyle:UIBarStyleBlack];
    [self setSyncToolbarItems:[NSArray arrayWithObjects:
                               [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                               syncButton, 
                               [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                               nil]];
    if (!observations) {
        [self loadData];
    }
    
    [[[[RKObjectManager sharedManager] client] requestQueue] setDelegate:self]; // TODO, might have to unset this when this view closes?
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [self setSyncLabel:nil];
    [self setSyncButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self checkSyncStatus];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self setToolbarItems:nil animated:YES];
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
    [self.navigationController setToolbarHidden:YES];
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
        [vc setObservation:o];
    } else if ([segue.identifier isEqualToString:@"EditObservationSegue"]) {
        ObservationDetailViewController *vc = [segue destinationViewController];
        [vc setDelegate:self];
        Observation *o = [observations 
                          objectAtIndex:[[self.tableView 
                                          indexPathForSelectedRow] row]];
        [vc setObservation:o];
    } else if ([segue.identifier isEqualToString:@"LoginSegue"]) {
        LoginViewController *vc = (LoginViewController *)[segue.destinationViewController topViewController];
        [vc setDelegate:self];
    }
}

# pragma marl INObservationDetailViewControllerDelegate methods
- (void)observationDetailViewControllerDidSave:(ObservationDetailViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [[self navigationController] popToViewController:self animated:YES];
    [self loadData];
    [[self tableView] reloadData];
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
    NSDate *now = [NSDate date];
    for (Observation *o in objects) {
        [o setSyncedAt:now];
    }
    [[[RKObjectManager sharedManager] objectStore] save];
    
    self.syncedObservationsCount += 1;
    if (syncActivityView) {
        [[syncActivityView activityLabel] setText:
         [NSString stringWithFormat:
          @"Syncing %d of %d observations", 
          self.syncedObservationsCount + 1, 
          self.observationsToSyncCount]];
    }
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    if (syncActivityView) {
        [DejalBezelActivityView removeView];
        syncActivityView = nil;
    }
    
    [[[[RKObjectManager sharedManager] client] requestQueue] cancelAllRequests];
    
    // KLUDGE!! RestKit doesn't seem to handle failed auth very well
    bool jsonParsingError = [error.domain isEqualToString:@"JKErrorDomain"] && error.code == -1;
    bool authFailure = [error.domain isEqualToString:@"NSURLErrorDomain"] && error.code == -1012;
    if (jsonParsingError || authFailure) {
        [self performSegueWithIdentifier:@"LoginSegue" sender:self];
    } else {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Whoops!" 
                                                     message:[NSString stringWithFormat:@"Looks like there was an error: %@", error.localizedDescription]
                                                    delegate:self 
                                           cancelButtonTitle:@"OK" 
                                           otherButtonTitles:nil];
        [av show];
    }
    self.syncedObservationsCount = 0;
}

- (void)objectLoaderDidLoadUnexpectedResponse:(RKObjectLoader *)objectLoader
{
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
    [[self tableView] reloadData];
    [self checkSyncStatus];
    if (syncActivityView) {
        [DejalBezelActivityView removeView];
        syncActivityView = nil;
    }
}

@end
