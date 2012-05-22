//
//  ProjectsSearchController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/29/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Three20/Three20.h>
#import "ProjectsSearchController.h"
#import "Project.h"

static const int ProjectCellImageTag = 1;
static const int ProjectCellTitleTag = 2;
static NSString *CellIdentifier = @"ProjectCell";

@implementation ProjectsSearchController

- (id)initWithSearchDisplayController:(UISearchDisplayController *)searchDisplayController
{
    self = [super initWithSearchDisplayController:searchDisplayController];
    if (self) {
        self.model = Project.class;
        self.searchURL = @"/projects/search?q=%@";
    }
    return self;
}

#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    Project *p = [self.searchResults objectAtIndex:indexPath.row];
    TTImageView *imageView = (TTImageView *)[cell viewWithTag:ProjectCellImageTag];
    [imageView unsetImage];
    UILabel *title = (UILabel *)[cell viewWithTag:ProjectCellTitleTag];
    title.text = p.title;
    imageView.defaultImage = [UIImage imageNamed:@"projects"];
    imageView.urlPath = p.iconURL;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Project *p = [self.searchResults objectAtIndex:indexPath.row];
    [self.searchDisplayController.searchContentsController performSegueWithIdentifier:@"ProjectListSegue" sender:p];
}

#pragma mark - UISearchDisplayControllerDelegate
- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView
{
    [tableView registerNib:[UINib nibWithNibName:@"ProjectTableViewCell" bundle:nil] 
    forCellReuseIdentifier:CellIdentifier];   
}

@end
