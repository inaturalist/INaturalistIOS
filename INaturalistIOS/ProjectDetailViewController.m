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

static const int LeaveProjectAlertViewTag = 1;

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
        self.joinButton.title = NSLocalizedString(@"Leave",nil);
        self.joinButton.tintColor = [UIColor blackColor];
    } else {
        self.joinButton.title = NSLocalizedString(@"Join",nil);
        self.joinButton.tintColor = [UIColor colorWithRed:155/255.0 
                                                    green:196/255.0 
                                                     blue:48/255.0 
                                                    alpha:1];
    }
}

- (IBAction)clickedViewButton:(id)sender {
    NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSString *url =[NSString stringWithFormat:@"%@/projects/%@?locale=%@-%@",
                    INatWebBaseURL, self.project.cachedSlug, language, countryCode];
    TTNavigator* navigator = [TTNavigator navigator];
    [navigator openURLAction:[TTURLAction actionWithURLPath:url]];
}

- (IBAction)clickedJoin:(id)sender {
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Internet required",nil)
                                                     message:NSLocalizedString(@"You must be connected to the Internet to do this.",nil)
                                                    delegate:self 
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
        [av show];
        return;
    }
    if (self.projectUser && self.projectUser.syncedAt) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to leave this project?",nil)
                                                     message:NSLocalizedString(@"This will also remove your observations from this project.",nil)
                                                    delegate:self 
                                           cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                           otherButtonTitles:NSLocalizedString(@"Leave",nil), nil];
        av.tag = LeaveProjectAlertViewTag;
        [av show];
    } else {
        if ([(INaturalistAppDelegate *)UIApplication.sharedApplication.delegate loggedIn]) {
            [self join];
        } else {
            [self performSegueWithIdentifier:@"LoginSegue" sender:self];
        }
    }
}

- (IBAction)clickedClose:(id)sender {
    [[self parentViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (void)join
{
    [DejalBezelActivityView activityViewForView:self.navigationController.view
                                      withLabel:NSLocalizedString(@"Joining...",nil)];
    if (!self.projectUser) {
        self.projectUser = [ProjectUser object];
        self.projectUser.project = self.project;
        self.projectUser.projectID = self.project.recordID;
    }
    [[RKObjectManager sharedManager] postObject:self.projectUser usingBlock:^(RKObjectLoader *loader) {
        loader.delegate = self;
        loader.resourcePath = [NSString stringWithFormat:@"/projects/%d/join", self.project.recordID.intValue];
        loader.objectMapping = [ProjectUser mapping];
    }];
}

- (void)leave
{
    [DejalBezelActivityView activityViewForView:self.navigationController.view
                                      withLabel:NSLocalizedString(@"Leaving...",nil)];
    [[RKObjectManager sharedManager] deleteObject:self.projectUser usingBlock:^(RKObjectLoader *loader) {
        loader.delegate = self;
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
        return NSLocalizedString(@"No description.", nil);
    }
}

- (NSString *)projectTerms
{
    if (self.project && self.project.terms && self.project.terms.length != 0) {
        return [self.project.terms stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    } else {
        return NSLocalizedString(@"No terms.", nil);
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
    NSString *currentLanguage = [[NSLocale preferredLanguages] objectAtIndex:0];
    if ([currentLanguage compare:@"es"] == NSOrderedSame){
        [self.navigationController.navigationBar setTitleTextAttributes:
         [NSDictionary dictionaryWithObject:[UIFont boldSystemFontOfSize:17] forKey:UITextAttributeFont]];
    }

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

- (NSInteger)heightForHTML:(NSString *)html
{
    NSString *s = [html stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
    s = [s stringByReplacingOccurrencesOfString:@"<BR>" withString:@"\n"];
    s = [s stringByReplacingOccurrencesOfString:@"<p>" withString:@""];
    s = [s stringByReplacingOccurrencesOfString:@"</p>" withString:@"\n"];
    s = [s stringByRemovingHTML];
    s = [s stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
    CGSize size = [s sizeWithFont:[UIFont systemFontOfSize:15] 
                    constrainedToSize:CGSizeMake(320, 1000) 
                    lineBreakMode:UILineBreakModeWordWrap];
    return size.height;
}

#pragma mark - Table view delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 0) {
        return [self heightForHTML:[self projectDescription]] + 10;
    } else if (indexPath.section == 1 && indexPath.row == 0) {
        return [self heightForHTML:[self projectTerms]] + 10;
    } else if (indexPath.section == 2 && indexPath.row == 0) {
        NSArray *terms = [self.project.projectObservationRuleTerms componentsSeparatedByString:@"|"];
        NSString *first;
        if (self.project.projectObservationRuleTerms && self.project.projectObservationRuleTerms.length > 0) {
            first = [terms objectAtIndex:0];
        } else {
            first = [NSString stringWithString:NSLocalizedString(@"No observation rules",nil)];
        }
        CGSize s = [first sizeWithFont:[UIFont systemFontOfSize:15] 
                     constrainedToSize:CGSizeMake(320, 1000) 
                         lineBreakMode:UILineBreakModeWordWrap];
        return s.height * terms.count + 10;
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
            label.text = NSLocalizedString(@"Description",nil);
            break;
        case 1:
            label.text = NSLocalizedString(@"Terms",nil);
            break;
        case 2:
            label.text = NSLocalizedString(@"Observation Rules",nil);
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
    } else if (indexPath.section == 2 && indexPath.row == 0) {
        rowContent = (TTStyledTextLabel *)[cell viewWithTag:2];
        if (!rowContent.text) {
            NSArray *terms = [self.project.projectObservationRuleTerms componentsSeparatedByString:@"|"];
            NSMutableString *termsString;
            if (self.project.projectObservationRuleTerms && self.project.projectObservationRuleTerms.length > 0) {
                termsString = [NSMutableString stringWithString:@"<div><ul>"];
                for (NSString *term in terms) {
                    [termsString appendString:[NSString stringWithFormat:@"\n<li>- %@</li>", term]];
                }
                [termsString appendString:@"</ul></div>"];
            } else {
                termsString = [NSMutableString stringWithFormat:@"<div>%@.</div>", NSLocalizedString(@"No observation rules", nil)];
            }
            rowContent.text = [TTStyledText textFromXHTML:termsString
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
        [self clickedClose:nil];
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
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Whoops!",nil)
                                                     message:[NSString stringWithFormat:NSLocalizedString(@"Looks like there was an error: %@",nil), error.localizedDescription]
                                                    delegate:self 
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
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

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag != LeaveProjectAlertViewTag) {
        return;
    }
    
    if (buttonIndex == 1) {
        [self leave];
    }
}
@end
