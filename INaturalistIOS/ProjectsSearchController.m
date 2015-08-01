//
//  ProjectsSearchController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/29/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>

#import "ProjectsSearchController.h"
#import "Project.h"
#import "UIImage+INaturalist.h"
#import "ProjectTableViewCell.h"

static NSString *CellIdentifier = @"ProjectCell";

@implementation ProjectsSearchController

- (id)initWithSearchDisplayController:(UISearchDisplayController *)searchDisplayController
{
    self = [super initWithSearchDisplayController:searchDisplayController];
    if (self) {
        self.model = Project.class;
        NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
        NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
        self.searchURL = [NSString stringWithFormat:@"/projects/search?locale=%@-%@&q=%%@", language, countryCode];
    }
    return self;
}

#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ProjectTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[ProjectTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    Project *p = [self.searchResults objectAtIndex:indexPath.row];
    cell.titleLabel.text = p.title;
    [cell.projectImage sd_cancelCurrentImageLoad];
    [cell.projectImage sd_setImageWithURL:[NSURL URLWithString:p.iconURL]
                 placeholderImage:[UIImage inat_defaultProjectImage]];
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
