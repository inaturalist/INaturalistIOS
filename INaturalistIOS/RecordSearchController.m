//
//  RecordSearchController.m
//  
//
//  Created by Ken-ichi Ueda on 3/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RecordSearchController.h"
#import "INatModel.h"

@implementation RecordSearchController
@synthesize searchResults = _searchResults;
@synthesize savedSearchTerm = _savedSearchTerm;
@synthesize searchDisplayController = _searchDisplayController;
@synthesize model = _model;
@synthesize searchURL = _searchURL;
@synthesize requestTimer = _requestTimer;
@synthesize delegate = _delegate;

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

- (NSString *)searchURL
{
    if (!_searchURL) {
        if (self.model) {
            _searchURL = [NSString stringWithFormat:@"/%@/search?q=%@", NSStringFromClass(self.model).underscore.pluralize];
        } else {
            _searchURL = [NSString stringWithFormat:@"/search?q=%@"];
        }
    }
    return _searchURL;
}

- (NSPredicate *)predicateForQuery:(NSString *)query
{
    return [NSPredicate predicateWithFormat:@"title CONTAINS[cd] %@", query];
}

- (void)searchLocal:(NSString *)query
{
    NSFetchRequest *r = [self.model fetchRequest];
    [r setPredicate:[self predicateForQuery:query]];
    [r setFetchLimit:500];
    self.searchResults = [NSMutableArray arrayWithArray:[self.model objectsWithFetchRequest:r]];
}

- (void)searchRemote
{
    if (self.savedSearchTerm.length && self.savedSearchTerm.length < 3) {
        return;
    }
    NSString *url = [NSString stringWithFormat:self.searchURL, self.savedSearchTerm];
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] 
                                                 objectMapping:[self.model mapping]
                                                      delegate:self];
}

#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSObject *o = [self.searchResults objectAtIndex:indexPath.row];
    if ([self.delegate respondsToSelector:@selector(recordSearchControllerCellForRecord:inTableView:)]) {
        return [self.searchDisplayController.searchContentsController performSelector:@selector(recordSearchControllerCellForRecord:inTableView:) 
                                                                           withObject:o
                                                                           withObject:tableView];
    } else {
        static NSString *CellIdentifier = @"RecordCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        cell.textLabel.text = o.description;
        return cell;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchResults.count;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(recordSearchControllerSelectedRecord:)]) {
        [self.delegate performSelector:@selector(recordSearchControllerSelectedRecord:) 
                            withObject:[self.searchResults objectAtIndex:indexPath.row]];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(recordSearchControllerClickedAccessoryForRecord:)]) {
        [self.delegate performSelector:@selector(recordSearchControllerClickedAccessoryForRecord:) 
                            withObject:[self.searchResults objectAtIndex:indexPath.row]];
    }
}

#pragma mark - UISearchDisplayControllerDelegate
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    self.savedSearchTerm = searchString;
    [self searchLocal:searchString];
    
    bool lengthOk = searchString.length > 2;
    bool netOk = [[[RKClient sharedClient] reachabilityObserver] isNetworkReachable];
    
    if (lengthOk && netOk) {
        if (self.requestTimer) {
            [self.requestTimer invalidate];
        }
        self.requestTimer = [NSTimer scheduledTimerWithTimeInterval:1 
                                                             target:self 
                                                           selector:@selector(searchRemote)
                                                           userInfo:nil 
                                                            repeats:NO];
    }
    return YES;
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
