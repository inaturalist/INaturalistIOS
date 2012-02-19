//
//  LoginViewController.m
//  INaturalistIOS
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (IBAction)signIn:(id)sender {
    [DejalBezelActivityView activityViewForView:self.view withLabel:@"Signing in..."];
    [[RKClient sharedClient] setUsername:[usernameField text]];
    [[RKClient sharedClient] setPassword:[passwordField text]];
    NSLog(@"password: %@", [RKClient sharedClient].password);
    [[RKClient sharedClient] get:@"/observations/new" delegate:self];
}

#pragma mark RKRequestDelegate methods
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
