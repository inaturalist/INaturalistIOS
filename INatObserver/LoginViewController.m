//
//  LoginViewController.m
//  INatObserver
//
//  Created by Ken-ichi Ueda on 2/17/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "LoginViewController.h"
#import "DejalActivityView.h"

@implementation LoginViewController
@synthesize usernameField, passwordField, delegate;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (IBAction)cancel:(id)sender {
    [[self parentViewController] dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [self setUsernameField:nil];
    [self setPasswordField:nil];
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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{
//#warning Potentially incomplete method implementation.
//    // Return the number of sections.
//    return 0;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//#warning Incomplete method implementation.
//    // Return the number of rows in the section.
//    return 0;
//}

//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    static NSString *CellIdentifier = @"Cell";
//    
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//    if (cell == nil) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
//    }
//    
//    // Configure the cell...
//    
//    return cell;
//}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    // Navigation logic may go here. Create and push another view controller.
//    /*
//     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
//     // ...
//     // Pass the selected object to the new view controller.
//     [self.navigationController pushViewController:detailViewController animated:YES];
//     */
//}

- (IBAction)signIn:(id)sender {
    [DejalBezelActivityView activityViewForView:self.view withLabel:@"Signing in..."];
    [[RKClient sharedClient] setUsername:[usernameField text]];
    [[RKClient sharedClient] setPassword:[passwordField text]];
    NSLog(@"password: %@", [RKClient sharedClient].password);
    [[RKClient sharedClient] get:@"/observations/new" delegate:self];
}

#pragma mark RKRequestDelegate methods
//– request:didLoadResponse:
- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response
{
    NSLog(@"loaded response: %@", response);
    [[NSUserDefaults standardUserDefaults] setValue:[usernameField text] forKey:INatUsernamePrefKey];
    [[NSUserDefaults standardUserDefaults] setValue:[passwordField text] forKey:INatPasswordPrefKey];
    [[self parentViewController] dismissViewControllerAnimated:YES completion:nil];
    if (self.delegate && [self.delegate respondsToSelector:@selector(loginViewControllerDidLogIn:)]) {
        [self.delegate loginViewControllerDidLogIn:self];
    }
    [DejalBezelActivityView removeView];
}
//– request:didFailLoadWithError:
- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error
{
    NSLog(@"did fail with error: %@", error);
    UIAlertView *av;
    // KLUDGE!! RestKit doesn't seem to handle failed auth very well
    bool jsonParsingError = [error.domain isEqualToString:@"JKErrorDomain"] && error.code == -1;
    bool authFailure = [error.domain isEqualToString:@"NSURLErrorDomain"] && error.code == -1012;
    if (jsonParsingError || authFailure) {
        [[RKClient sharedClient] setUsername:nil];
        [[RKClient sharedClient] setPassword:nil];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:INatUsernamePrefKey];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:INatPasswordPrefKey];
        if (self.delegate && [self.delegate respondsToSelector:@selector(loginViewControllerFailedToLogIn:)]) {
            [self.delegate loginViewControllerFailedToLogIn:self];
        }
        
        av = [[UIAlertView alloc] initWithTitle:@"Log in failed" 
                                   message:@"Username or password were invalid." 
                                  delegate:self 
                         cancelButtonTitle:@"OK" 
                         otherButtonTitles:nil];
        
    } else {
        av = [[UIAlertView alloc] initWithTitle:@"Whoops!" 
                                        message:[NSString stringWithFormat:@"Looks like there was an unexpected error: %@", error.localizedDescription]
                                       delegate:self 
                              cancelButtonTitle:@"OK" 
                              otherButtonTitles:nil];
    }
    [DejalBezelActivityView removeView];
    [av show];
    NSLog(@"removing activity view");
}
//– requestDidStartLoad:
//– request:didSendBodyData:totalBytesWritten:totalBytesExpectedToWrite:
//– request:didReceivedData:totalBytesReceived:totalBytesExectedToReceive:
//– requestDidCancelLoad:
//– requestDidTimeout:

//- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObject:(id)object
//{
//    NSLog(@"loaded object");
//    // success, save the settings
//    [[NSUserDefaults standardUserDefaults] setValue:[usernameField text] forKey:INatUsernamePrefKey];
//    [[NSUserDefaults standardUserDefaults] setValue:[passwordField text] forKey:INatPasswordPrefKey];
//    [[self parentViewController] dismissViewControllerAnimated:YES completion:nil];
//    [self.delegate loginViewControllerDidLogIn:self];
//    [DejalBezelActivityView removeView];
//}

//- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
//    NSLog(@"object loader failed with error: %@", [error debugDescription]);
//    
//    // KLUDGE!! RestKit doesn't seem to handle failed auth very well
//    bool jsonParsingError = [error.domain isEqualToString:@"JKErrorDomain"] && error.code == -1;
//    bool authFailure = [error.domain isEqualToString:@"NSURLErrorDomain"] && error.code == -1012;
//    if (jsonParsingError || authFailure) {
//        [[RKClient sharedClient] setUsername:nil];
//        [[RKClient sharedClient] setPassword:nil];
//        [[NSUserDefaults standardUserDefaults] removeObjectForKey:INatUsernamePrefKey];
//        [[NSUserDefaults standardUserDefaults] removeObjectForKey:INatPasswordPrefKey];
//        [self.delegate loginViewControllerFailedToLogIn:self];
//    }
//    NSLog(@"removing activity view");
//    [DejalBezelActivityView removeView];
//}

//- (void)objectLoaderDidLoadUnexpectedResponse:(RKObjectLoader *)objectLoader
//{
//    NSLog(@"unexpected error!");
//    [DejalBezelActivityView removeViewAnimated:YES];
//}
//
//- (void)objectLoaderDidFinishLoading:(RKObjectLoader *)objectLoader
//{
//    NSLog(@"objectLoaderDidFinishLoading");
//    [DejalBezelActivityView removeViewAnimated:YES];
//}

#pragma mark UITextFieldDelegate methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSLog(@"textField: %@", textField);
    NSLog(@"usernameField: %@", usernameField);
    [textField resignFirstResponder];
    if (textField == usernameField) {
        [passwordField becomeFirstResponder];
    } else if (textField == passwordField) {
        [self signIn:nil];
    }
    return YES;
}
@end
