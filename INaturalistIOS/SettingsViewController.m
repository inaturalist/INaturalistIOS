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
#import "TutorialViewController.h"
#import "INatUITabBarController.h"

static const int UsernameCellTag = 0;
static const int AccountActionCellTag = 1;
static const int TutorialActionCellTag = 2;
static const int ContactActionCellTag = 3;
static const int VersionCellTag = 4;

@implementation SettingsViewController

@synthesize versionText = _versionText;

- (void)initUI
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    UITableViewCell *usernameCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITableViewCell *accountActionCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    UITableViewCell *tutorialActionCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    UITableViewCell *contactActionCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
    UITableViewCell *creditsCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
    usernameCell.tag = UsernameCellTag;
    accountActionCell.tag = AccountActionCellTag;
    tutorialActionCell.tag = TutorialActionCellTag;
    contactActionCell.tag = ContactActionCellTag;
    creditsCell.backgroundView = nil;
    
    if ([defaults objectForKey:INatUsernamePrefKey]) {
        usernameCell.detailTextLabel.text = [defaults objectForKey:INatUsernamePrefKey];
        accountActionCell.textLabel.text = NSLocalizedString(@"Sign out",nil);
    } else {
        usernameCell.detailTextLabel.text = NSLocalizedString(@"Unknown",nil);
        accountActionCell.textLabel.text = NSLocalizedString(@"Sign in",nil);
    }
    
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    self.versionText = [NSString stringWithFormat:NSLocalizedString(@"Version %@, build %@",nil),
                        [info objectForKey:@"CFBundleShortVersionString"],
                        [info objectForKey:@"CFBundleVersion"]];
    
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
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure?",nil)
                                                 message:NSLocalizedString(@"This will delete all your observations on this device.  It will not affect any observations you've uploaded to iNaturalist.",nil)
                                                delegate:self 
                                       cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                       otherButtonTitles:NSLocalizedString(@"Sign out",nil), nil];
    [av show];
}

- (void)signOut
{
    [DejalBezelActivityView activityViewForView:self.view withLabel:NSLocalizedString(@"Signing out...",nil)];
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
    NSError *error = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
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
    [(INatUITabBarController *)self.tabBarController setObservationsTabBadge];
    [self initUI];
}

- (void)launchTutorial
{
    TutorialViewController *vc = [[TutorialViewController alloc] initWithDefaultTutorial];
    UINavigationController *modalNavController = [[UINavigationController alloc]
                                                  initWithRootViewController:vc];
    [self presentViewController:modalNavController animated:YES completion:nil];
}

- (void)sendSupportEmail
{
    NSString *email = [NSString stringWithFormat:@"mailto://help@inaturalist.org?cc=&subject=iNaturalist iPhone help: version %@", 
                       self.versionText];
    email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
}

- (void)networkUnreachableAlert
{
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                                 message:NSLocalizedString(@"Try again next time you're connected to the Internet.",nil)
                                                delegate:self 
                                       cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                       otherButtonTitles:nil];
    [av show];
}

#pragma mark - lifecycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initUI];
}

#pragma mark - UITableView
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 3 && indexPath.row == 0) {
        cell.textLabel.text = self.versionText;
        cell.backgroundView = nil;
        cell.tag = VersionCellTag;
    }
}

#pragma mark - UITableViewDataSource
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    switch (cell.tag) {
        case UsernameCellTag:
            if ([defaults objectForKey:INatUsernamePrefKey]) {
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            } else {
                if ([[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
                    [self performSegueWithIdentifier:@"SignInFromSettingsSegue" sender:self];
                } else {
                    [self networkUnreachableAlert];
                }
            }
            break;
        case AccountActionCellTag:
            if ([defaults objectForKey:INatUsernamePrefKey]) {
                [self clickedSignOut];
            } else {
                if ([[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
                    [self performSegueWithIdentifier:@"SignInFromSettingsSegue" sender:self];
                } else {
                    [self networkUnreachableAlert];
                }
            }
            break;
        case TutorialActionCellTag:
            [self launchTutorial];
            break;
        case ContactActionCellTag:
            [self sendSupportEmail];
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
