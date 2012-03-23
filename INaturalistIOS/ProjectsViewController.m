//
//  ProjectsViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/12/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Three20/Three20.h>
#import "ProjectsViewController.h"
#import "ProjectDetailViewController.h"
#import "Project.h"
#import "ProjectUser.h"
#import "DejalActivityView.h"

static const int ProjectCellImageTag = 1;
static const int ProjectCellTitleTag = 2;

@implementation ProjectsViewController
@synthesize projectUsers = _projectUsers;
@synthesize loader = _loader;
@synthesize lastSyncedAt = _lastSyncedAt;
@synthesize noContentLabel = _noContentLabel;

- (void)loadData
{
    NSArray *projectUsers = [ProjectUser.all sortedArrayUsingComparator:^NSComparisonResult(ProjectUser *obj1, ProjectUser *obj2) {
        return [obj1.project.title.lowercaseString compare:obj2.project.title.lowercaseString];
    }];
    self.projectUsers = [NSMutableArray arrayWithArray:projectUsers];
    [self checkEmpty];
}

- (IBAction)clickedSync:(id)sender {
    [self sync];
}

- (void)checkEmpty
{
    if (self.projectUsers.count == 0) {
        if (!self.noContentLabel) {
            self.noContentLabel = [[UILabel alloc] init];
            self.noContentLabel.text = @"You don't have any projects yet.";
            self.noContentLabel.backgroundColor = [UIColor clearColor];
            self.noContentLabel.textColor = [UIColor grayColor];
            self.noContentLabel.numberOfLines = 0;
            [self.noContentLabel sizeToFit];
            self.noContentLabel.textAlignment = UITextAlignmentCenter;
            self.noContentLabel.center = CGPointMake(self.view.center.x, 
                                                     self.tableView.rowHeight * 3 + (self.tableView.rowHeight / 2));
        }
        [self.view addSubview:self.noContentLabel];
    } else if (self.noContentLabel) {
        [self.noContentLabel removeFromSuperview];
    }
}

- (void)sync
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *username = [defaults objectForKey:INatUsernamePrefKey];
    if (username && username.length > 0) {
        [DejalBezelActivityView activityViewForView:self.navigationController.view
                                          withLabel:@"Syncing projects..."];
        [[RKObjectManager sharedManager] loadObjectsAtResourcePath:[NSString stringWithFormat:@"/projects/user/%@", username]
                                                     objectMapping:[ProjectUser mapping] 
                                                          delegate:self];
        self.lastSyncedAt = [NSDate date];
    } else {
        [self performSegueWithIdentifier:@"LoginSegue" sender:self];
    }
}

- (void)stopSync
{
    [DejalBezelActivityView removeView];
    [[[[RKObjectManager sharedManager] client] requestQueue] cancelAllRequests];
    [self loadData];
    [[self tableView] reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ProjectSegue"]) {
        ProjectDetailViewController *vc = [segue destinationViewController];
        ProjectUser *pu = [self.projectUsers 
                          objectAtIndex:[[self.tableView 
                                          indexPathForSelectedRow] row]];
        [vc setProject:pu.project];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableView deselectRowAtIndexPath:[self.tableView.indexPathsForSelectedRows objectAtIndex:0] animated:YES];
    [self loadData];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    NSString *username = [NSUserDefaults.standardUserDefaults objectForKey:INatUsernamePrefKey];
    if (self.projectUsers.count == 0 && username && !self.lastSyncedAt) {
        [self sync];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.projectUsers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ProjectCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    ProjectUser *pu = [self.projectUsers objectAtIndex:[indexPath row]];
    TTImageView *imageView = (TTImageView *)[cell viewWithTag:ProjectCellImageTag];
    [imageView unsetImage];
    UILabel *title = (UILabel *)[cell viewWithTag:ProjectCellTitleTag];
    title.text = pu.project.title;
    imageView.defaultImage = [UIImage imageNamed:@"projects"];
    imageView.urlPath = pu.project.iconURL;
    
    return cell;
}

#pragma mark - RKObjectLoaderDelegate
- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects
{
    NSLog(@"loaded %d objects", objects.count);
    if (objects.count == 0) return;
    NSDate *now = [NSDate date];
    for (INatModel *o in objects) {
        [o setSyncedAt:now];
    }
    
    NSArray *rejects = [ProjectUser objectsWithPredicate:[NSPredicate predicateWithFormat:@"syncedAt < %@", now]];
    for (ProjectUser *pu in rejects) {
        [pu deleteEntity];
    }
    
    [[[RKObjectManager sharedManager] objectStore] save];
    
    [self stopSync];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    // was running into a bug in release build config where the object loader was 
    // getting deallocated after handling an error.  This is a kludge.
    self.loader = objectLoader;
    
    [self stopSync];
    NSString *errorMsg;
    bool jsonParsingError = false, authFailure = false;
    switch (objectLoader.response.statusCode) {
            // UNPROCESSABLE ENTITY
        case 422:
            errorMsg = @"Unprocessable entity";
            break;
            
        default:
            // KLUDGE!! RestKit doesn't seem to handle failed auth very well
            jsonParsingError = [error.domain isEqualToString:@"JKErrorDomain"] && error.code == -1;
            authFailure = [error.domain isEqualToString:@"NSURLErrorDomain"] && error.code == -1012;
            errorMsg = error.localizedDescription;
    }
    
    if (jsonParsingError || authFailure) {
        [self performSegueWithIdentifier:@"LoginSegue" sender:self];
    } else {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Whoops!" 
                                                     message:[NSString stringWithFormat:@"Looks like there was an error: %@", errorMsg]
                                                    delegate:self 
                                           cancelButtonTitle:@"OK" 
                                           otherButtonTitles:nil];
        [av show];
    }
}

#pragma mark - LoginViewControllerDelegate
- (void)loginViewControllerDidLogIn:(LoginViewController *)controller
{
    [self sync];
}
@end
