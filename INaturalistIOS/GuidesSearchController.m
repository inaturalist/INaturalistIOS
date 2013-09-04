//
//  GuidesSearchController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/1/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <Three20/Three20.h>
#import "GuidesSearchController.h"
#import "Guide.h"

static const int GuideCellImageTag = 1;
static const int GuideCellTitleTag = 2;
static NSString *CellIdentifier = @"GuideCell";

@implementation GuidesSearchController

- (id)initWithSearchDisplayController:(UISearchDisplayController *)searchDisplayController
{
    self = [super initWithSearchDisplayController:searchDisplayController];
    if (self) {
        self.model = Guide.class;
        NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
        NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
        self.searchURL = [NSString stringWithFormat:@"/guides/search.json?locale=%@-%@&q=%%@", language, countryCode];
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
    Guide *g = [self.searchResults objectAtIndex:indexPath.row];
    TTImageView *imageView = (TTImageView *)[cell viewWithTag:GuideCellImageTag];
    [imageView unsetImage];
    UILabel *title = (UILabel *)[cell viewWithTag:GuideCellTitleTag];
    title.text = g.title;
    imageView.defaultImage = [UIImage imageNamed:@"guides"];
    imageView.urlPath = g.iconURL;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Guide *p = [self.searchResults objectAtIndex:indexPath.row];
    [self.searchDisplayController.searchContentsController performSegueWithIdentifier:@"GuideListSegue" sender:p];
}

#pragma mark - UISearchDisplayControllerDelegate
- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView
{
    [tableView registerNib:[UINib nibWithNibName:@"ProjectTableViewCell" bundle:nil]
    forCellReuseIdentifier:CellIdentifier];
}

@end
