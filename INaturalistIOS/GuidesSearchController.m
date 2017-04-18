//
//  GuidesSearchController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/1/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>

#import "GuidesSearchController.h"
#import "Guide.h"
#import "UIImage+INaturalist.h"

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
    Guide *g = [self.searchResults objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:GuideCellImageTag];
    [imageView cancelImageRequestOperation];
    UILabel *title = (UILabel *)[cell viewWithTag:GuideCellTitleTag];
    title.text = g.title;
    
    [imageView setImageWithURL:[NSURL URLWithString:g.iconURL]
              placeholderImage:[UIImage inat_defaultGuideImage]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Guide *g = [self.searchResults objectAtIndex:indexPath.row];
    [self.searchDisplayController.searchContentsController performSegueWithIdentifier:@"GuideDetailSegue" sender:g];
}

#pragma mark - UISearchDisplayControllerDelegate
- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView
{
    [tableView registerNib:[UINib nibWithNibName:@"ProjectTableViewCell" bundle:nil] forCellReuseIdentifier:CellIdentifier];
}

@end
