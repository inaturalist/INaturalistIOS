//
//  ProjectChooserViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/16/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <MBProgressHUD/MBProgressHUD.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <RestKit/RestKit.h>

#import "ProjectChooserViewController.h"
#import "Project.h"
#import "ProjectUser.h"
#import "Analytics.h"
#import "UIImage+INaturalist.h"
#import "ProjectTableViewCell.h"
#import "INaturalistAppDelegate.h"
#import "LoginController.h"
#import "User.h"
#import "OnboardingLoginViewController.h"
#import "INatReachability.h"

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

- (void)presentSignupPrompt:(NSString *)reason {
    [[Analytics sharedClient] event:kAnalyticsEventNavigateOnboardingScreenLogin
                     withProperties:@{ @"via": @"project chooser" }];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Onboarding" bundle:nil];
    OnboardingLoginViewController *login = [storyboard instantiateViewControllerWithIdentifier:@"onboarding-login"];
    login.skippable = NO;
    [self presentViewController:login animated:YES completion:nil];
}


#pragma mark - lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!self.projectUsers) [self loadData];
    if (!self.chosenProjects) self.chosenProjects = [[NSMutableArray alloc] init];
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
    
    if ((!self.projectUsers || self.projectUsers.count == 0) && [[INatReachability sharedClient] isNetworkReachable]) {
    	INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    	if ([appDelegate.loginController isLoggedIn]) {
    		User *me = [appDelegate.loginController fetchMe];
	        NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
	        NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
	        NSString *url =[NSString stringWithFormat:@"/projects/user/%@.json?locale=%@-%@",
	                        me.login, language, countryCode];
            [[Analytics sharedClient] debugLog:@"Network - Load projects for user"];
            
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.labelText = NSLocalizedString(@"Loading...",nil);
            hud.removeFromSuperViewOnHide = YES;
            hud.dimBackground = YES;

            RKObjectManager *objectManager = [RKObjectManager sharedManager];
            [objectManager loadObjectsAtResourcePath:url
                                          usingBlock:^(RKObjectLoader *loader) {
                                              loader.delegate = self;
                                              // handle naked array in JSON by explicitly directing the loader which mapping to use
                                              loader.objectMapping = [objectManager.mappingProvider objectMappingForClass:[ProjectUser class]];
                                          }];
        }
    }
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
    [cell.projectImage cancelImageRequestOperation];
    [cell.projectImage setImageWithURL:[NSURL URLWithString:pu.project.iconURL]
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
    cell.accessoryType = UITableViewCellAccessoryNone;
    ProjectUser *pu = [self.projectUsers objectAtIndex:indexPath.row];
    [self.chosenProjects removeObject:pu.project];
}

#pragma mark - RKObjectLoaderDelegate
- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects {
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    });
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    });
    
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
        [self presentSignupPrompt:NSLocalizedString(@"You must be logged in to do that.", @"Login reason prompt from project chooser.")];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Whoops!",nil)
                                                                       message:[NSString stringWithFormat:NSLocalizedString(@"Looks like there was an error: %@",nil), errorMsg]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
