//
//  INatObserverViewController.m
//  INatObserver
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "INatObserverViewController.h"
#import "LoginViewController.h"
#import "Observation.h"

@implementation INatObserverViewController
@synthesize syncLabel;
@synthesize syncButton;
@synthesize observations;
@synthesize observationsToSyncCount = _observationsToSyncCount;
@synthesize syncToolbarItems = _syncToolbarItems;

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
                                    @"synced_at = nil OR synced_at < local_updated_at"]];
//    [RKObjectManager sharedManager].client.username = @"username";
//    [RKObjectManager sharedManager].client.password = @"password";
    [RKObjectManager sharedManager].client.authenticationType = RKRequestAuthenticationTypeHTTPBasic;
    
    for (Observation *o in observationsToSync) {
        if (o.synced_at) {
//            [[RKObjectManager sharedManager] putObject:o delegate:self];
            [[RKObjectManager sharedManager] putObject:o mapResponseWith:[Observation mapping] delegate:self];
        } else {
//            [[RKObjectManager sharedManager] postObject:o delegate:self];
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
        NSLog(@"destroying observation");
        [[observations objectAtIndex:indexPath.row] destroy];
        NSLog(@"removing obs from local array");
        [observations removeObjectAtIndex:indexPath.row];
        NSLog(@"removing row from tableview");
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObject:(id)object
{
    NSLog(@"posted %@", object);
}

- (void)loadData
{
    NSLog(@"loadData");
    [self setObservations:[[NSMutableArray alloc] initWithArray:[Observation all]]];
    [self setObservationsToSyncCount:0];
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
                                     [NSPredicate predicateWithFormat:@"synced_at = nil OR synced_at < local_updated_at"]] count];
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
}


# pragma mark TableViewController methods


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [observations count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Observation *o = [observations objectAtIndex:[indexPath row]];
//    UITableViewCell *cell = [[self tableView] dequeueReusableCellWithIdentifier:@"ObservationTableCell"];
//    if (!cell) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UITableViewCell"];
//    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ObservationTableCell"];
    [[cell textLabel] setText:[o species_guess]];
    return cell;
}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    Observation *o = [[Observation all] objectAtIndex:[indexPath row]];
//    NSLog(@"selected observation %@", o);
//    [self setSelectedObservation:o];
//}

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
        INObservationFormViewController *vc = (INObservationFormViewController *)[segue.destinationViewController topViewController];
        [vc setDelegate:self];
        Observation *o = [Observation object];
        [vc setObservation:o];
    } else if ([segue.identifier isEqualToString:@"EditObservationSegue"]) {
        INObservationFormViewController *vc = [segue destinationViewController];
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

# pragma marl INObservationFormViewControllerDelegate methods
- (void)observationFormViewControllerDidSave:(INObservationFormViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [[self navigationController] popToViewController:self animated:YES];
    [self loadData];
    [[self tableView] reloadData];
}

- (void)observationFormViewControllerDidCancel:(INObservationFormViewController *)controller
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
    NSLog(@"didLoadObject");
    NSDate *now = [NSDate date];
    for (Observation *o in objects) {
        [o setSynced_at:now];
    }
    [[[RKObjectManager sharedManager] objectStore] save];
    [[self tableView] reloadData];
    [self checkSyncStatus];
}

//- (void)objectLoader:(RKObjectLoader *)loader willMapData:(inout id *)mappableData
//{
//    NSLog(@"willMapData: %@", *mappableData);
//}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    NSLog(@"object loader failed with error: %@", [error debugDescription]);
    
    [[[[RKObjectManager sharedManager] client] requestQueue] cancelAllRequests];
    
    // KLUDGE!! RestKit doesn't seem to handle failed auth very well
    bool jsonParsingError = [error.domain isEqualToString:@"JKErrorDomain"] && error.code == -1;
    bool authFailure = [error.domain isEqualToString:@"NSURLErrorDomain"] && error.code == -1012;
    if (jsonParsingError || authFailure) {
        [self performSegueWithIdentifier:@"LoginSegue" sender:self];
    } else {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Whoops!" 
                                                     message:[NSString stringWithFormat:@"Looks like there was an unexpected error: %@", error.localizedDescription]
                                                    delegate:self 
                                           cancelButtonTitle:@"OK" 
                                           otherButtonTitles:nil];
        [av show];
    }
}

- (void)objectLoaderDidLoadUnexpectedResponse:(RKObjectLoader *)objectLoader
{
    NSLog(@"object loader unexpected response");
}

@end
