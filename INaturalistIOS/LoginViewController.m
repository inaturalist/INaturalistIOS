//
//  LoginViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/17/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "LoginViewController.h"
#import "DejalActivityView.h"
#import "INatWebController.h"

@implementation LoginViewController
@synthesize usernameField, passwordField, delegate;

- (IBAction)cancel:(id)sender {
    [[self parentViewController] dismissViewControllerAnimated:YES completion:nil];
    if (self.delegate && [self.delegate respondsToSelector:@selector(loginViewControllerDidCancel:)]) {
        [self.delegate performSelector:@selector(loginViewControllerDidCancel:) withObject:self];
    }
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
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (IBAction)signIn:(id)sender {
    [DejalBezelActivityView activityViewForView:self.view withLabel:@"Signing in..."];
    [[RKClient sharedClient] setUsername:[usernameField text]];
    [[RKClient sharedClient] setPassword:[passwordField text]];
    [[RKClient sharedClient] post:@"/session.json" 
                           params:[NSDictionary dictionaryWithObjectsAndKeys:
                                   [usernameField text], @"login", 
                                   [passwordField text], @"password",
                                   nil] 
                         delegate:self];
}

#pragma mark RKRequestDelegate methods
- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response
{
    [DejalBezelActivityView removeView];
    if (response.statusCode == 200) {
        NSString *jsonString = [[NSString alloc] initWithData:response.body 
                                                     encoding:NSUTF8StringEncoding];
        NSError* error = nil;
        id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:@"application/json"];
        NSDictionary *parsedData = [parser objectFromString:jsonString error:&error];
        if (parsedData == nil && error) {
            // Parser error...
            [self failedLogin];
            return;
        }
        
        [[NSUserDefaults standardUserDefaults] setValue:[parsedData objectForKey:@"login"] 
                                                 forKey:INatUsernamePrefKey];
        [[NSUserDefaults standardUserDefaults] setValue:[passwordField text] 
                                                 forKey:INatPasswordPrefKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        if (self.delegate && [self.delegate respondsToSelector:@selector(loginViewControllerDidLogIn:)]) {
            [self.delegate loginViewControllerDidLogIn:self];
        }
        [[self parentViewController] dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self failedLogin];
    }
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error
{
    // KLUDGE!! RestKit doesn't seem to handle failed auth very well
    bool jsonParsingError = [error.domain isEqualToString:@"JKErrorDomain"] && error.code == -1;
    bool authFailure = [error.domain isEqualToString:@"NSURLErrorDomain"] && error.code == -1012;
    if (jsonParsingError || authFailure) {
        [self failedLogin];
    } else {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Whoops!" 
                                        message:[NSString stringWithFormat:@"Looks like there was an unexpected error: %@", error.localizedDescription]
                                       delegate:self 
                              cancelButtonTitle:@"OK" 
                              otherButtonTitles:nil];
        [av show];
    }
    [DejalBezelActivityView removeView];
}

- (void)failedLogin
{
    [[RKClient sharedClient] setUsername:nil];
    [[RKClient sharedClient] setPassword:nil];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:INatUsernamePrefKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:INatPasswordPrefKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (self.delegate && [self.delegate respondsToSelector:@selector(loginViewControllerFailedToLogIn:)]) {
        [self.delegate loginViewControllerFailedToLogIn:self];
    }
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Log in failed" 
                                    message:@"Username or password were invalid." 
                                   delegate:self 
                          cancelButtonTitle:@"OK" 
                          otherButtonTitles:nil];
    [av show];
}

#pragma mark UITextFieldDelegate methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    if (textField == usernameField) {
        [passwordField becomeFirstResponder];
    } else if (textField == passwordField) {
        [self signIn:nil];
    }
    return YES;
}

#pragma mark UITableView delegate methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        if ([[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
            UINavigationController *nc = self.navigationController;
            INatWebController *webController = [[INatWebController alloc] init];
            NSURL *url = [NSURL URLWithString:
                          [NSString stringWithFormat:@"%@/users/new.mobile", INatBaseURL]];
            [webController openURL:url];
            webController.delegate = self;
            [nc pushViewController:webController animated:YES];
        } else {
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Internet connection required" 
                                                         message:@"Try again next time you're connected to the Internet." 
                                                        delegate:self 
                                               cancelButtonTitle:@"OK" 
                                               otherButtonTitles:nil];
            [av show];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark UIAlertViewDelegate methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) return;
    NSURL *url = [NSURL URLWithString:
                  [NSString stringWithFormat:@"%@/users/new.mobile", INatBaseURL]];
    [[UIApplication sharedApplication] openURL:url];
}

#pragma mark - TTWebControllerDelegate
- (BOOL)webController:(TTWebController *)controller 
              webView:(UIWebView *)webView 
shouldStartLoadWithRequest:(NSURLRequest *)request 
       navigationType:(UIWebViewNavigationType)navigationType
{
    if ([request.URL.path isEqualToString:@"/users"] || [request.URL.path hasPrefix:@"/users/new"]) {
        return YES;
    }
    [self.navigationController popViewControllerAnimated:YES];
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Welcome to iNaturalist!" 
                                                 message:@"Now that you've signed up you can sign in with the username and password you just created.  Don't forget to check for your confirmation email as well." 
                                                delegate:self 
                                       cancelButtonTitle:@"OK" 
                                       otherButtonTitles:nil];
    [av show];
    return NO;
}

@end
