//
//  RecordSearchController.m
//  
//
//  Created by Ken-ichi Ueda on 3/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RecordSearchController.h"
#import "INatModel.h"
#import "Analytics.h"
#import "INatReachability.h"

@implementation RecordSearchController
@synthesize searchResults = _searchResults;
@synthesize savedSearchTerm = _savedSearchTerm;
@synthesize searchDisplayController = _searchDisplayController;
@synthesize model = _model;
@synthesize searchURL = _searchURL;
@synthesize requestTimer = _requestTimer;
@synthesize delegate = _delegate;
@synthesize noContentLabel = _noContentLabel;
@synthesize isLoading = _isLoading;

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

- (void)dealloc {
    [[[RKClient sharedClient] requestQueue] cancelRequestsWithDelegate:self];
}

- (NSString *)searchURL
{
    if (!_searchURL) {
        if (self.model) {
            _searchURL = [NSString stringWithFormat:@"/%@/search?q=%%@", NSStringFromClass(self.model).underscore.pluralize];
        } else {
            _searchURL = [NSString stringWithFormat:@"/search?q=%%@"];
        }
    }
    return _searchURL;
}

- (NSPredicate *)predicateForQuery:(NSString *)query
{
    query = [query stringByReplacingOccurrencesOfString:@" " withString:@"*"];
    query = [query stringByReplacingOccurrencesOfString:@" " withString:@"-"];
    query = [NSString stringWithFormat:@"*%@*", query];
    return [NSPredicate predicateWithFormat:@"title LIKE[cd] %@", query];
}

- (void)searchLocal:(NSString *)query
{
    NSFetchRequest *r = [self.model fetchRequest];
    query = [query stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
    [r setPredicate:[self predicateForQuery:query]];
    [r setFetchLimit:500];
    self.searchResults = [NSMutableArray arrayWithArray:[self.model objectsWithFetchRequest:r]];
}

- (void)searchRemote
{
    if (self.savedSearchTerm.length && self.savedSearchTerm.length < 3) {
        return;
    }
    self.isLoading = YES;
    NSString *url = [NSString stringWithFormat:self.searchURL, self.savedSearchTerm];
    [[Analytics sharedClient] debugLog:@"Network - Record search"];
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                                 objectMapping:[self.model mapping]
                                                      delegate:self];
    [self checkRemoteLoading];
}

- (void)checkRemoteLoading
{
    if (self.searchResults.count == 0 && self.isLoading) {
        UITableView *tableView = self.searchDisplayController.searchResultsTableView;
        if (!self.noContentLabel) {
            self.noContentLabel = [[UILabel alloc] init];
            self.noContentLabel.text = @"Searching...";
            self.noContentLabel.font = [UIFont boldSystemFontOfSize:20];
            self.noContentLabel.backgroundColor = [UIColor whiteColor];
            self.noContentLabel.textColor = [UIColor grayColor];
            self.noContentLabel.numberOfLines = 0;
            [self.noContentLabel sizeToFit];
            self.noContentLabel.textAlignment = NSTextAlignmentCenter;
            self.noContentLabel.center = CGPointMake(tableView.center.x, 
                                                     tableView.rowHeight * 2 + (tableView.rowHeight / 2));
            self.noContentLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        }
        [tableView addSubview:self.noContentLabel];
    } else if (self.noContentLabel) {
        [self.noContentLabel removeFromSuperview];
    }
}

#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSObject *o;
    if (self.allowsFreeTextSelection && self.savedSearchTerm.length > 0 && indexPath.section == 1) {
        o = nil;
    } else {
        o = [self.searchResults objectAtIndex:indexPath.row];
    }
    
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.allowsFreeTextSelection && self.savedSearchTerm.length > 0) {
        return 2;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.allowsFreeTextSelection && self.savedSearchTerm.length > 0 && section == 1) {
        return 1;
    } else {
        return self.searchResults.count;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.allowsFreeTextSelection && self.savedSearchTerm.length > 0 && section == 0) {
        if (self.searchResults.count > 0) {
            return @"iNaturalist";
        } else {
            return NSLocalizedString(@"No iNaturalist Results", nil);
        }
    } else if (self.allowsFreeTextSelection && self.savedSearchTerm.length > 0 && section == 1) {
        return NSLocalizedString(@"Placeholder", nil);
    } else {
        return nil;
    }
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.allowsFreeTextSelection && self.savedSearchTerm.length > 0 && indexPath.section == 1) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(recordSearchControllerSelectedRecord:)]) {
        [self.delegate performSelector:@selector(recordSearchControllerSelectedRecord:) 
                            withObject:[self.searchResults objectAtIndex:indexPath.row]];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    if (self.allowsFreeTextSelection && self.savedSearchTerm.length > 0 && indexPath.section == 1) {
        // do nothing
    } else if (self.delegate && [self.delegate respondsToSelector:@selector(recordSearchControllerClickedAccessoryForRecord:)]) {
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
    bool netOk = [[INatReachability sharedClient] isNetworkReachable];
    
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
    NSError *error = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
    [self searchLocal:self.savedSearchTerm];
    [self.searchDisplayController.searchResultsTableView reloadData];
    self.isLoading = NO;
    [self checkRemoteLoading];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error
{
    //    just assume no results
    self.isLoading = NO;
    [self checkRemoteLoading];
}

@end
