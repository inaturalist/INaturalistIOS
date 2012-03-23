//
//  SettingsViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/27/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "SettingsViewController.h"
#import "LoginViewController.h"
#import "DejalActivityView.h"
#import "Observation.h"
#import "ProjectUser.h"
#import "ProjectObservation.h"
#import "DeletedRecord.h"

static const int UsernameCellTag = 0;
static const int AccountActionCellTag = 1;

@implementation SettingsViewController

- (void)initUI
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    UITableViewCell *usernameCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITableViewCell *accountActionCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    UITableViewCell *creditsCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    usernameCell.tag = UsernameCellTag;
    accountActionCell.tag = AccountActionCellTag;
    creditsCell.backgroundView = nil;
    
    if ([defaults objectForKey:INatUsernamePrefKey]) {
        usernameCell.detailTextLabel.text = [defaults objectForKey:INatUsernamePrefKey];
        accountActionCell.textLabel.text = @"Sign out";
    } else {
        usernameCell.detailTextLabel.text = @"Unknown";
        accountActionCell.textLabel.text = @"Sign in";
    }
    [self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if (segue.identifier == @"SignInFromSettingsSegue") {
        LoginViewController *vc = (LoginViewController *)[segue.destinationViewController topViewController];
        [vc setDelegate:self];
    }
}

- (void)clickedSignOut
{
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Are you sure?" 
                                                 message:@"This will delete all your observations on this device.  It will not affect any observations you've uploaded to iNaturalist." 
                                                delegate:self 
                                       cancelButtonTitle:@"Cancel" 
                                       otherButtonTitles:@"Sign out", nil];
    [av show];
}

- (void)signOut
{
    [DejalBezelActivityView activityViewForView:self.view withLabel:@"Signing out..."];
    for (UIViewController *vc in self.tabBarController.viewControllers) {
        if ([vc isKindOfClass:UINavigationController.class]) {
            [(UINavigationController *)vc popToRootViewControllerAnimated:NO];
        }
    }
    [Observation deleteAll];
    [ProjectUser deleteAll];
    [ProjectObservation deleteAll]; 
    for (DeletedRecord *dr in [DeletedRecord allObjects]) {
         [dr deleteEntity];
    }
    [[[RKObjectManager sharedManager] objectStore] save];
    [self localSignOut];
    [DejalBezelActivityView removeView];
}

- (void)localSignOut
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:INatUsernamePrefKey];
    [defaults removeObjectForKey:INatPasswordPrefKey];
    [defaults synchronize];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [RKClient.sharedClient setUsername:nil];
    [RKClient.sharedClient setPassword:nil];
    [self initUI];
}

#pragma mark - lifecycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initUI];
}

#pragma mark - UITableViewDataSource
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    switch (cell.tag) {
        case AccountActionCellTag:
            if ([defaults objectForKey:INatUsernamePrefKey]) {
                [self clickedSignOut];
            } else {
                [self performSegueWithIdentifier:@"SignInFromSettingsSegue" sender:self];
            }
            break;
            
        default:
            break;
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self signOut];
    } else {
        [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    }
}

@end
