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
@synthesize searchResults = _searchResults;
@synthesize savedSearchTerm = _savedSearchTerm;
@synthesize searchDisplayController = _searchDisplayController;

- (id)initWithSearchDisplayController:(UISearchDisplayController *)searchDisplayController
{
    self = [super init];
    if (self) {
        self.searchDisplayController = searchDisplayController;
        searchDisplayController.delegate = self;
        searchDisplayController.searchResultsDataSource = self;
        searchDisplayController.searchResultsDelegate = self;
    }
    return self;
}

- (void)searchLocal:(NSString *)query
{
    NSFetchRequest *r = [Project fetchRequest];
    [r setPredicate:[NSPredicate predicateWithFormat:@"title CONTAINS[cd] %@", query]];
    self.searchResults = [NSMutableArray arrayWithArray:[Project objectsWithFetchRequest:r]];
}

- (void)searchRemote:(NSString *)query
{
    // TODO loading indicator
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:[NSString stringWithFormat:@"/projects/search?q=%@", query] 
                                                 objectMapping:[Project mapping] 
                                                      delegate:self];
}

#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    Project *p = [self.searchResults objectAtIndex:indexPath.row];
    TTImageView *imageView = (TTImageView *)[cell viewWithTag:1];
    [imageView unsetImage];
    UILabel *title = (UILabel *)[cell viewWithTag:2];
    title.text = p.title;
    imageView.defaultImage = [UIImage imageNamed:@"projects"];
    imageView.urlPath = p.iconURL;
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchResults.count;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Project *p = [self.searchResults objectAtIndex:indexPath.row];
    [self.searchDisplayController.searchContentsController performSegueWithIdentifier:@"ProjectSegue" sender:p];
}

#pragma mark - UISearchDisplayControllerDelegate
- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView
{
    [tableView registerNib:[UINib nibWithNibName:@"ProjectTableViewCell" bundle:nil] 
    forCellReuseIdentifier:CellIdentifier];   
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    self.savedSearchTerm = searchString;
    
    if (searchString.length > 2 && [[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        [self searchRemote:searchString];
    } else {
        [self searchLocal:searchString];
    }
    return YES;
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    self.savedSearchTerm = nil;
}

#pragma mark - RKObjectLoaderDelegate
- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects
{
    NSDate *now = [NSDate date];
    INatModel *o;
    for (int i = 0; i < objects.count; i++) {
        o = [objects objectAtIndex:i];
        [o setSyncedAt:now];
    }
    [[[RKObjectManager sharedManager] objectStore] save];
    [self searchLocal:self.savedSearchTerm];
    [self.searchDisplayController.searchResultsTableView reloadData];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error
{
//    NSLog(@"objectLoader didFailWithError: %@", error);
//    just assume no results
}

@end
