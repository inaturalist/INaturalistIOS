//
//  TaxaSearchController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/30/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Realm/Realm.h>

#import "TaxaSearchController.h"
#import "Taxon.h"
#import "TaxonPhoto.h"
#import "ImageStore.h"
#import "TaxaAPI.h"
#import "ExploreTaxon.h"
#import "ExploreTaxonRealm.h"

@interface TaxaSearchController ()
@property (readonly) TaxaAPI *api;
@end

@implementation TaxaSearchController

- (TaxaAPI *)api {
	static TaxaAPI *_api = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
    	_api = [[TaxaAPI alloc] init];
    });
    return _api;
}

- (id)initWithSearchDisplayController:(UISearchDisplayController *)searchDisplayController
{
    self = [super initWithSearchDisplayController:searchDisplayController];
    if (self) {
        self.model = Taxon.class;
    }
    return self;
}

#pragma mark - UISearchDisplayControllerDelegate
- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView
{
	[tableView registerNib:[UINib nibWithNibName:@"TaxonCell" bundle:nil] forCellReuseIdentifier:@"TaxonCell"];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	[self.delegate recordSearchControllerClickedAccessoryForRecord:[self.searchResults objectAtIndex:indexPath.item]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.allowsFreeTextSelection && indexPath.section == 0) {
    	// species guess row
    	[self.delegate recordSearchControllerSelectedRecord:nil];
    } else {
    	[self.delegate recordSearchControllerSelectedRecord:[self.searchResults objectAtIndex:indexPath.row]];
    }
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
	if (![self.savedSearchTerm isEqualToString:searchString]) {
		self.savedSearchTerm = searchString;
		[self searchRemote];
	}
	return YES;
}

- (void)searchRemote {
	// query node, put into realm, update UI
	[self.api taxaMatching:self.savedSearchTerm handler:^(NSArray *results, NSInteger count, NSError *error) {
		// put the results into realm
		RLMRealm *realm = [RLMRealm defaultRealm];
		[realm beginWriteTransaction];
		for (ExploreTaxon *taxon in results) {
			ExploreTaxonRealm *etr = [[ExploreTaxonRealm alloc] initWithMantleModel:taxon];
			[realm addOrUpdateObject:etr];
		}
		[realm commitWriteTransaction];
		
		// update the UI
		dispatch_async(dispatch_get_main_queue(), ^{
			[self searchLocal:self.savedSearchTerm];
		});
	}];
	
}

- (void)searchLocal:(NSString *)term {
	
	term = [term stringByFoldingWithOptions:NSDiacriticInsensitiveSearch
                                     locale:[NSLocale currentLocale]];
	// query realm
	RLMResults *results = [ExploreTaxonRealm objectsWhere:@"searchableCommonName contains[c] %@ OR searchableScientificName contains[c] %@", term, term];
	self.searchResults = results;
	[self.searchDisplayController.searchResultsTableView reloadData];
}

@end
