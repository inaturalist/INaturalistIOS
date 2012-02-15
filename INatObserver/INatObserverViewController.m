//
//  INatObserverViewController.m
//  INatObserver
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "INatObserverViewController.h"
#import "Observation.h"

@implementation INatObserverViewController
@synthesize selectedObservation;

- (id)init
{
    NSLog(@"INatObserverViewController init");
    self = [super initWithStyle:UITableViewStyleGrouped];
    [[self tableView] setSeparatorColor:[UIColor lightGrayColor]];
    [[self tableView] setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    NSLog(@"INatObserverViewController post init");
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    return [self init];
}


# pragma mark TableViewController methods


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"numberOfRowsInSection, count: %d", [[Observation all] count]);
    return [[Observation all] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Observation *o = [[Observation all] objectAtIndex:[indexPath row]];
//    UITableViewCell *cell = [[self tableView] dequeueReusableCellWithIdentifier:@"ObservationTableCell"];
//    if (!cell) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UITableViewCell"];
//    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ObservationTableCell"];
    [[cell textLabel] setText:[o speciesGuess]];
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
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
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
    INObservationFormViewController *vc = [segue destinationViewController];
    [vc setDelegate:self];
    if ([[segue identifier] isEqualToString:@"AddObservationSegue"]) {
        Observation *o = [[Observation alloc] init];
        [vc setObservation:o];
    } else if ([segue.identifier isEqualToString:@"EditObservationSegue"]) {
        Observation *o = [[Observation all] 
                          objectAtIndex:[[self.tableView 
                                          indexPathForSelectedRow] row]];
        [vc setObservation:o];
    }
}

# pragma marl INObservationFormViewControllerDelegate methods
- (void)observationFormViewControllerDidSave:(INObservationFormViewController *)controller
{
    NSLog(@"observationFormViewControllerDidSave");
    [self dismissViewControllerAnimated:YES completion:nil];
    [[self navigationController] popToViewController:self animated:YES];
    [self setSelectedObservation:nil];
    [[self tableView] reloadData];
}

- (void)observationFormViewControllerDidCancel:(INObservationFormViewController *)controller
{
    NSLog(@"observationFormViewControllerDidCancel");
    [self dismissViewControllerAnimated:YES completion:nil];
    [[self navigationController] popToViewController:self animated:YES];
    [self setSelectedObservation:nil];
}

- (IBAction)addObservation:(id)sender {
}
@end
