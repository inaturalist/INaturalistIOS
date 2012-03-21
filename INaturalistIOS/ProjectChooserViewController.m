//
//  ProjectChooserViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/16/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Three20/Three20.h>
#import "ProjectChooserViewController.h"
#import "Project.h"
#import "ProjectUser.h"

static const int ProjectCellImageTag = 1;
static const int ProjectCellTitleTag = 2;

@implementation ProjectChooserViewController

@synthesize delegate = _delegate;
@synthesize projectUsers = _projectUsers;
@synthesize chosenProjects = _chosenProjects;
@synthesize noContentLabel = _noContentLabel;

- (void)loadData
{
    self.projectUsers = [ProjectUser all];
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

#pragma mark - lifecycle
- (void)viewDidLoad
{
    if (!self.projectUsers) [self loadData];
    if (!self.chosenProjects) self.chosenProjects = [[NSMutableArray alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self checkEmpty];
}

- (void)viewDidAppear:(BOOL)animated
{
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
    
    ProjectUser *pu = [self.projectUsers objectAtIndex:[indexPath row]];
    TTImageView *imageView = (TTImageView *)[cell viewWithTag:ProjectCellImageTag];
    [imageView unsetImage];
    UILabel *title = (UILabel *)[cell viewWithTag:ProjectCellTitleTag];
    title.text = pu.project.title;
    imageView.defaultImage = [UIImage imageNamed:@"projects"];
    imageView.urlPath = pu.project.iconURL;
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

@end
