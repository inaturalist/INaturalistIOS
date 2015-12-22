//
//  ProjectChooserViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/16/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <FontAwesomeKit/FAKIonIcons.h>

#import "ProjectChooserViewController.h"
#import "Project.h"
#import "ProjectUser.h"
#import "Analytics.h"
#import "UIImage+INaturalist.h"

#import "ProjectTableViewCell.h"

#import "SignupSplashViewController.h"
#import "INaturalistAppDelegate+TransitionAnimators.h"
#import "SignUserForGolanProject.h"


@implementation ProjectChooserViewController

@synthesize delegate = _delegate;
@synthesize projectUsers = _projectUsers;
@synthesize chosenProjects = _chosenProjects;
@synthesize noContentLabel = _noContentLabel;
@synthesize loader = _loader;

- (void)loadData
{
    
    self.projectUsers = [[ProjectUser all] sortedArrayUsingComparator:^NSComparisonResult(ProjectUser *obj1, ProjectUser *obj2) {
        return [obj1.project.title.lowercaseString compare:obj2.project.title.lowercaseString];
    }];
    // be defensive
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"project != nil"];
    self.projectUsers = [self.projectUsers filteredArrayUsingPredicate:predicate];
    
    // Find the Golan project and put it at index 0 to be the first.
    ProjectUser *golanProject;
    for(ProjectUser *pu in self.projectUsers) {
        if([pu.projectID intValue] == kGolanWildlifeProjectID) {
            golanProject = pu;
            break;
        }
    }
    if(golanProject) {
        NSMutableArray *mArray = [self.projectUsers mutableCopy];
        [mArray removeObject:golanProject];
        [mArray insertObject:golanProject atIndex:0];
        self.projectUsers = [mArray copy];
    }
}

- (IBAction)clickedCancel:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(projectChooserViewControllerDidCancel:)]) {
        [self.delegate performSelector:@selector(projectChooserViewControllerDidCancel) 
                            withObject:self];
    }
    [[self parentViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)clickedDone:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(projectChooserViewController:choseProjects:)]) {
        [self.delegate performSelector:@selector(projectChooserViewController:choseProjects:) 
                            withObject:self 
                            withObject:self.chosenProjects];
    }
    [[self parentViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)checkEmpty
{
    if (self.projectUsers.count == 0) {
        if (!self.noContentLabel) {
            self.noContentLabel = [[UILabel alloc] init];
            self.noContentLabel.text = NSLocalizedString(@"You don't have any projects yet.",nil);
            self.noContentLabel.backgroundColor = [UIColor clearColor];
            self.noContentLabel.textColor = [UIColor grayColor];
            self.noContentLabel.numberOfLines = 0;
            [self.noContentLabel sizeToFit];
            self.noContentLabel.textAlignment = NSTextAlignmentCenter;
            self.noContentLabel.center = CGPointMake(self.view.center.x, 
                                                     self.tableView.rowHeight * 2 + (self.tableView.rowHeight / 2));
            self.noContentLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        }
        [self.view addSubview:self.noContentLabel];
    } else if (self.noContentLabel) {
        [self.noContentLabel removeFromSuperview];
    }
}


#pragma mark - lifecycle
- (void)viewDidLoad
{
    if (!self.projectUsers) [self loadData];
    if (!self.chosenProjects) self.chosenProjects = [[NSMutableArray alloc] init];
    
    if ((!self.projectUsers || self.projectUsers.count == 0) && [[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *username = [defaults objectForKey:INatUsernamePrefKey];
        NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
        NSString *language = [NSLocale localeForCurrentLanguage];
        NSString *url =[NSString stringWithFormat:@"/projects/user/%@.json?locale=%@-%@",
                        username,
                        language,
                        countryCode];
        if (username && username.length > 0) {
            [SVProgressHUD showWithStatus:NSLocalizedString(@"Loading...",nil)];
            [[Analytics sharedClient] debugLog:@"Network - Load projects for user"];
            [[RKObjectManager sharedManager] loadObjectsAtResourcePath:url
                                                         objectMapping:[ProjectUser mapping]
                                                              delegate:self];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self checkEmpty];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    for (int i = 0; i < self.projectUsers.count; i++) {
        ProjectUser *pu = [self.projectUsers objectAtIndex:i];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if ([self.chosenProjects containsObject:pu.project]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }
    
    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateProjectChooser];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateProjectChooser];
}

- (void)dealloc {
    [[[RKClient sharedClient] requestQueue] cancelRequestsWithDelegate:self];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.projectUsers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ProjectCell";
    ProjectTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    ProjectUser *pu = [self.projectUsers objectAtIndex:[indexPath row]];
    cell.titleLabel.text = pu.project.title;
    [cell.projectImage sd_cancelCurrentImageLoad];
    [cell.projectImage sd_setImageWithURL:[NSURL URLWithString:pu.project.iconURL]
                 placeholderImage:[UIImage inat_defaultProjectImage]];
    if ([self.chosenProjects containsObject:pu.project]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    ProjectUser *pu = [self.projectUsers objectAtIndex:indexPath.row];
    [self.chosenProjects addObject:pu.project];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    ProjectUser *pu = [self.projectUsers objectAtIndex:indexPath.row];
    if([pu.projectID intValue] != kGolanWildlifeProjectID){
        cell.accessoryType = UITableViewCellAccessoryNone;
        [self.chosenProjects removeObject:pu.project];
    }
}

#pragma mark - RKObjectLoaderDelegate
- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects
{
    [SVProgressHUD showSuccessWithStatus:nil];
    NSDate *now = [NSDate date];
    for (INatModel *o in objects) {
        [o setSyncedAt:now];
    }
    
    if ([objectLoader.resourcePath rangeOfString:@"projects/user"].location != NSNotFound) {
        NSArray *rejects = [ProjectUser objectsWithPredicate:[NSPredicate predicateWithFormat:@"syncedAt < %@", now]];
        for (ProjectUser *pu in rejects) {
            [pu deleteEntity];
        }
    }
    
    NSError *error = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
    [self loadData];
    [self.tableView reloadData];
    [self checkEmpty];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    // was running into a bug in release build config where the object loader was
    // getting deallocated after handling an error.  This is a kludge.
    self.loader = objectLoader;
    
    [SVProgressHUD dismiss];
    
    NSString *errorMsg;
    bool jsonParsingError = false, authFailure = false;
    switch (objectLoader.response.statusCode) {
            // Unauthorized
        case 401:
            authFailure = true;
            // UNPROCESSABLE ENTITY
        case 422:
            errorMsg = NSLocalizedString(@"Unprocessable entity",nil);
            break;
        default:
            // KLUDGE!! RestKit doesn't seem to handle failed auth very well
            jsonParsingError = [error.domain isEqualToString:@"JKErrorDomain"] && error.code == -1;
            authFailure = [error.domain isEqualToString:@"NSURLErrorDomain"] && error.code == -1012;
            errorMsg = error.localizedDescription;
    }
    
    if (jsonParsingError || authFailure) {
        [[Analytics sharedClient] event:kAnalyticsEventNavigateSignupSplash
                         withProperties:@{ @"From": @"Project Chooser" }];
        SignupSplashViewController *svc = [[SignupSplashViewController alloc] initWithNibName:nil bundle:nil];
        svc.skippable = NO;
        svc.cancellable = YES;
        svc.reason = NSLocalizedString(@"You must be logged in to do that.", @"Login reason prompt from project chooser.");
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:svc];
        // for sizzle
        nav.delegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
        [self presentViewController:nav animated:YES completion:nil];
    } else {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Whoops!",nil)
                                                     message:[NSString stringWithFormat:NSLocalizedString(@"Looks like there was an error: %@",nil), errorMsg]
                                                    delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
        [av show];
    }
}

@end
