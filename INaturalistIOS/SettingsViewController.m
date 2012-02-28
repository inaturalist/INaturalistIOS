//
//  SettingsViewController.m
//  INaturalistIOS
//
//  Created by Ken-ichi Ueda on 2/27/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "SettingsViewController.h"
#import "LoginViewController.h"
#import "DejalActivityView.h"

static const int UsernameCellTag = 0;
static const int AccountActionCellTag = 1;

@implementation SettingsViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initUI];
}

- (void)initUI
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    UITableViewCell *usernameCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITableViewCell *accountActionCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    usernameCell.tag = UsernameCellTag;
    accountActionCell.tag = AccountActionCellTag;
    
    if ([defaults objectForKey:INatUsernamePrefKey]) {
        usernameCell.detailTextLabel.text = [defaults objectForKey:INatUsernamePrefKey];
        accountActionCell.textLabel.text = @"Sign out";
    } else {
        usernameCell.detailTextLabel.text = @"Unknown";
        accountActionCell.textLabel.text = @"Sign in";
    }
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    switch (cell.tag) {
        case AccountActionCellTag:
            if ([defaults objectForKey:INatUsernamePrefKey]) {
                [self signOut];
            } else {
                [self performSegueWithIdentifier:@"SignInFromSettingsSegue" sender:self];
            }
            break;
            
        default:
            break;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if (segue.identifier == @"SignInFromSettingsSegue") {
        LoginViewController *vc = (LoginViewController *)[segue.destinationViewController topViewController];
        [vc setDelegate:self];
    }
}

- (void)signOut
{
    [DejalBezelActivityView activityViewForView:self.view withLabel:@"Signing out..."];
    [[RKClient sharedClient] get:@"/logout" delegate:self];
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error
{
    NSLog(@"request didFailLoadWithError: %@", error);
    [DejalBezelActivityView removeView];
}

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response
{
    NSLog(@"request didLoadResponse: %@", response);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:INatUsernamePrefKey];
    [defaults removeObjectForKey:INatPasswordPrefKey];
    [defaults synchronize];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self initUI];
    [DejalBezelActivityView removeView];
}

@end
