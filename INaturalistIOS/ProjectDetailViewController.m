//
//  ProjectDetailViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/27/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <TapkuLibrary/TapkuLibrary.h>
#import "ProjectDetailViewController.h"
#import "DejalActivityView.h"
#import "INaturalistAppDelegate.h"

@implementation ProjectDetailViewController
@synthesize project = _project;
@synthesize projectUser = _projectUser;
@synthesize sectionHeaderViews = _sectionHeaderViews;
@synthesize projectIcon = _projectIcon;
@synthesize joinButton = _joinButton;
@synthesize projectTitle = _projectTitle;

- (void)setProject:(Project *)project
{
    _project = project;
    self.projectUser = [ProjectUser objectWithPredicate:[NSPredicate predicateWithFormat:@"projectID = %@", project.recordID]];
}

- (void)setProjectUser:(ProjectUser *)projectUser
{
    _projectUser = projectUser;
    if (self.joinButton) {
        [self setupJoinButton];
    }
}

- (void)setupJoinButton
{
    if (self.projectUser && ![self.projectUser isNew]) {
        self.joinButton.title = @"Leave";
        self.joinButton.tintColor = [UIColor blackColor];
    } else {
        self.joinButton.title = @"Join";
        self.joinButton.tintColor = [UIColor colorWithRed:155/255.0 
                                                    green:196/255.0 
                                                     blue:48/255.0 
                                                    alpha:1];
    }
}

- (IBAction)clickedViewButton:(id)sender {
    NSString *url = [NSString stringWithFormat:@"%@/projects/%@", INatBaseURL, self.project.cachedSlug];
    TTNavigator* navigator = [TTNavigator navigator];
    [navigator openURLAction:[TTURLAction actionWithURLPath:url]];
}

- (IBAction)clickedJoin:(id)sender {
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Internet required" 
                                                     message:@"You must be connected to the Internet to do this."
                                                    delegate:self 
                                           cancelButtonTitle:@"OK" 
                                           otherButtonTitles:nil];
        [av show];
        return;
    }
    if (self.projectUser && self.projectUser.syncedAt) {
        [self leave];
    } else {
        if ([(INaturalistAppDelegate *)UIApplication.sharedApplication.delegate loggedIn]) {
            [self join];
        } else {
            [self performSegueWithIdentifier:@"LoginSegue" sender:self];
        }
    }
}

- (void)join
{
    [DejalBezelActivityView activityViewForView:self.navigationController.view
                                      withLabel:@"Joining..."];
    if (!self.projectUser) {
        self.projectUser = [ProjectUser object];
        self.projectUser.project = self.project;
        self.projectUser.projectID = self.project.recordID;
    }
    [[RKObjectManager sharedManager] postObject:self.projectUser delegate:self block:^(RKObjectLoader *loader) {
        loader.resourcePath = [NSString stringWithFormat:@"/projects/%d/join", self.project.recordID.intValue];
        loader.objectMapping = [ProjectUser mapping];
    }];
}

- (void)leave
{
    [DejalBezelActivityView activityViewForView:self.navigationController.view
                                      withLabel:@"Leaving..."];
    [[RKObjectManager sharedManager] deleteObject:self.projectUser delegate:self block:^(RKObjectLoader *loader) {
        loader.resourcePath = [NSString stringWithFormat:@"/projects/%d/leave", self.project.recordID.intValue];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"LoginSegue"]) {
        LoginViewController *vc = (LoginViewController *)[segue.destinationViewController topViewController];
        [vc setDelegate:self];
    }
}

- (NSString *)projectDescription
{
    if (self.project && self.project.desc && self.project.desc.length != 0) {
        return [self.project.desc stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    } else {
        return @"No description.";
    }
}

- (NSString *)projectTerms
{
    if (self.project && self.project.terms && self.project.terms.length != 0) {
        return [self.project.terms stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    } else {
        return @"No terms.";
    }
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    self.projectIcon.defaultImage = [UIImage imageNamed:@"projects.png"];
    self.projectIcon.urlPath = self.project.iconURL;
    self.projectTitle.text = self.project.title;
    
    CAGradientLayer *lyr = [CAGradientLayer layer];
    lyr.colors = [NSArray arrayWithObjects:
                  (id)[UIColor whiteColor].CGColor, 
                  (id)[UIColor colorWithRed:(220/255.0)  green:(220/255.0)  blue:(220/255.0)  alpha:1.0].CGColor, nil];
    lyr.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0], [NSNumber numberWithFloat:1], nil];
    lyr.frame = self.tableView.tableHeaderView.bounds;
    [self.tableView.tableHeaderView.layer insertSublayer:lyr atIndex:0];
    
    [self setupJoinButton];
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (void)viewDidUnload {
    [self setProjectIcon:nil];
    [self setProjectTitle:nil];
    [self setJoinButton:nil];
    [super viewDidUnload];
}

#pragma mark - Table view delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 0) {
        NSString *desc = [[self projectDescription] stringByRemovingHTML];
        desc = [desc stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
        CGSize s = [desc sizeWithFont:[UIFont systemFontOfSize:15] 
                    constrainedToSize:CGSizeMake(320, 1000) 
                        lineBreakMode:UILineBreakModeWordWrap];
        return s.height + 10;
    } else if (indexPath.section == 1 && indexPath.row == 0) {
        NSString *terms = [[self projectTerms] stringByRemovingHTML];
        terms = [terms stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
        CGSize s = [terms sizeWithFont:[UIFont systemFontOfSize:15] 
                     constrainedToSize:CGSizeMake(320, 1000) 
                         lineBreakMode:UILineBreakModeWordWrap];
        return s.height + 10;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (!self.sectionHeaderViews) {
        self.sectionHeaderViews = [[NSMutableDictionary alloc] init];
    }
    NSNumber *key = [NSNumber numberWithInt:section];
    if ([self.sectionHeaderViews objectForKey:key]) {
        return [self.sectionHeaderViews objectForKey:key];
    }
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 30)];
    header.backgroundColor = [UIColor whiteColor];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 300, 20)];
    label.font = [UIFont boldSystemFontOfSize:17];
    label.textColor = [UIColor darkGrayColor];
    switch (section) {
        case 0:
            label.text = @"Description";
            break;
        case 1:
            label.text = @"Terms";
            break;
        default:
            break;
    }
    [header addSubview:label];
    
    [self.sectionHeaderViews setObject:header forKey:key];
    return header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    TTStyledTextLabel *rowContent;
    if (indexPath.section == 0 && indexPath.row == 0) {
        rowContent = (TTStyledTextLabel *)[cell viewWithTag:1];
        if (!rowContent.text) {
            rowContent.text = [TTStyledText textFromXHTML:[NSString stringWithFormat:@"<div>%@</div>", [self projectDescription]]
                                               lineBreaks:YES
                                                     URLs:YES];
            [rowContent sizeToFit];
            rowContent.backgroundColor = [UIColor whiteColor];
        }
    } else if (indexPath.section == 1 && indexPath.row == 0) {
        rowContent = (TTStyledTextLabel *)[cell viewWithTag:1];
        if (!rowContent.text) {
            rowContent.text = [TTStyledText textFromXHTML:[NSString stringWithFormat:@"<div>%@</div>", [self projectTerms]]
                                               lineBreaks:YES
                                                     URLs:YES];
            [rowContent sizeToFit];
            rowContent.backgroundColor = [UIColor whiteColor];
        }
    }
    return cell;
}

#pragma mark - ScrollViewDelegate
// This is necessary to stop the section headers from sticking to the top of the screen
// http://stackoverflow.com/questions/664781/change-default-scrolling-behavior-of-uitableview-section-header
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat sectionHeaderHeight = 30;
    if (scrollView.contentOffset.y <= sectionHeaderHeight && scrollView.contentOffset.y >= 0) {
        scrollView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0);
    } else if (scrollView.contentOffset.y>=sectionHeaderHeight) {
        scrollView.contentInset = UIEdgeInsetsMake(-sectionHeaderHeight, 0, 0, 0);
    }
}

#pragma mark - RKObjectLoader
- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObject:(id)object
{
    ProjectUser *pu = object;
    if (pu) {
        pu.syncedAt = [NSDate date];
        [pu save];
    }
    self.projectUser = pu;
    [DejalBezelActivityView removeView];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error
{
    [DejalBezelActivityView removeView];
    if (objectLoader.response.statusCode == 401) {
        [self performSegueWithIdentifier:@"LoginSegue" sender:self];
    } else {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Whoops!" 
                                                     message:[NSString stringWithFormat:@"Looks like there was an error: %@", error.localizedDescription]
                                                    delegate:self 
                                           cancelButtonTitle:@"OK" 
                                           otherButtonTitles:nil];
        [av show];
    }
}

#pragma mark - LoginViewControllerDelegate
- (void)loginViewControllerDidLogIn:(LoginViewController *)controller
{
    [self clickedJoin:nil];
}

- (void)loginViewControllerDidCancel:(LoginViewController *)controller
{
    if (self.projectUser) {
        [self.projectUser destroy];
    }
}
@end
