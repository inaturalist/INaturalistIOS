//
//  TaxaSearchViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/30/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <MBProgressHUD/MBProgressHUD.h>
#import <AFNetworking/UIImageView+AFNetworking.h>

#import "TaxaSearchViewController.h"
#import "ImageStore.h"
#import "TaxonPhoto.h"
#import "TaxonDetailViewController.h"
#import "Analytics.h"
#import "FAKINaturalist.h"
#import "ExploreTaxon.h"
#import "ExploreTaxonRealm.h"
#import "ExploreTaxonRealm.h"
#import "ObsDetailTaxonCell.h"
#import "TaxaAPI.h"

#define MIN_CHARS_TAXA_SEARCH 3

@interface TaxaSearchViewController () <UISearchResultsUpdating, UISearchControllerDelegate>
@property UISearchController *searchController;
@property RLMResults <ExploreTaxonRealm *> *searchResults;
@end

@implementation TaxaSearchViewController

#pragma mark - UISearchControllerDelegate

- (void)didPresentSearchController:(UISearchController *)searchController {
    [searchController.searchBar becomeFirstResponder];
}

#pragma mark - Taxa Search Stuff

- (TaxaAPI *)api {
    static TaxaAPI *_api = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _api = [[TaxaAPI alloc] init];
    });
    return _api;
}


- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    self.tableView.backgroundView.hidden = TRUE;
    
    // don't bother querying api until the user has entered a reasonable amount of text
    if (searchController.searchBar.text.length < MIN_CHARS_TAXA_SEARCH) {
        self.searchResults = nil;
        [self.tableView reloadData];
        return;
    }
    
    // update the local results
    [self searchLocal:searchController.searchBar.text];
    
    
    // query node, put into realm, update UI
    [self.api taxaMatching:searchController.searchBar.text handler:^(NSArray *results, NSInteger count, NSError *error) {
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
            [self searchLocal:searchController.searchBar.text];
        });
    }];
}

- (void)searchLocal:(NSString *)term {
    term = [term stringByFoldingWithOptions:NSDiacriticInsensitiveSearch
                                     locale:[NSLocale currentLocale]];
    // query realm
    RLMResults *results = [ExploreTaxonRealm objectsWhere:@"searchableCommonName contains[c] %@ OR searchableScientificName contains[c] %@ OR searchableLastMatchedTerm contains[c] %@", term, term, term];
    
    self.searchResults = [results sortedResultsUsingDescriptors:@[
                                                                  [RLMSortDescriptor sortDescriptorWithProperty:@"rankLevel" ascending:NO],
                                                                  [RLMSortDescriptor sortDescriptorWithProperty:@"observationCount" ascending:NO],
                                                                  ]];
    [self.tableView reloadData];
}

- (void)clickedCancel:(UIControl *)control {
    [self.delegate taxaSearchViewControllerCancelled];
}

#pragma mark - UIViewController lifecycle
- (void)viewDidLoad {
	[super viewDidLoad];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = false;
    self.searchController.searchBar.placeholder = NSLocalizedString(@"Enter species name",
                                                                    @"placeholder text for taxon search bar");
    self.searchController.delegate = self;
    self.definesPresentationContext = true;
    
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerNib:[UINib nibWithNibName:@"TaxonCell" bundle:nil]
         forCellReuseIdentifier:@"TaxonCell"];
    if (self.hidesDoneButton) {
        self.navigationItem.rightBarButtonItem = nil;
    }
    
	[self.tableView registerNib:[UINib nibWithNibName:@"TaxonCell" bundle:nil] forCellReuseIdentifier:@"TaxonOneNameCell"];
	
	// show blank screen when empty
	self.tableView.tableFooterView = [UIView new];

    // user prefs determine autocorrection/spellcheck behavior of the species guess field
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kINatAutocompleteNamesPrefKey]) {
        [self.searchController.searchBar setAutocorrectionType:UITextAutocorrectionTypeYes];
        [self.searchController.searchBar setSpellCheckingType:UITextSpellCheckingTypeDefault];
    } else {
        [self.searchController.searchBar setAutocorrectionType:UITextAutocorrectionTypeNo];
        [self.searchController.searchBar setSpellCheckingType:UITextSpellCheckingTypeNo];
    }
	
	if (self.query && self.query.length > 0) {
		self.searchController.searchBar.text = self.query;
	}
    
    [self.searchController setActive:YES];
}

#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.allowsFreeTextSelection && indexPath.section == 1) {
        return [self cellForUnknownTaxonInTableView:tableView];
    } else {
        ExploreTaxonRealm *etr = [self.searchResults objectAtIndex:indexPath.item];
        return [self cellForTaxon:etr inTableView:tableView];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        // do nothing
    } else {
        ExploreTaxonRealm *etr = [self.searchResults objectAtIndex:indexPath.item];
        [self showTaxon:etr];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // add the ID or the species guess
    if (indexPath.section == 1) {
        [self.delegate taxaSearchViewControllerChoseSpeciesGuess:self.searchController.searchBar.text];
    } else {
        ExploreTaxonRealm *etr = [self.searchResults objectAtIndex:indexPath.item];
        [self.delegate taxaSearchViewControllerChoseTaxon:etr];
    }
}

#pragma mark - Table view data source
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.allowsFreeTextSelection && self.searchController.searchBar.text.length >= MIN_CHARS_TAXA_SEARCH) {
            return 2;
    } else {
        return 1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.allowsFreeTextSelection) {
        if (self.searchController.searchBar.text.length >= MIN_CHARS_TAXA_SEARCH && section == 0) {
            if (self.searchResults.count > 0) {
                return @"iNaturalist";
            } else {
                return NSLocalizedString(@"No iNaturalist Results", nil);
            }
        } else if (self.searchController.searchBar.text.length >= MIN_CHARS_TAXA_SEARCH && section == 1) {
            return NSLocalizedString(@"Placeholder", nil);
        }
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 1) {
        return 1;
    } else {
        return self.searchResults.count;
    }
}

#pragma mark - TaxonDetailViewControllerDelegate

- (void)taxonDetailViewControllerClickedActionForTaxonId:(NSInteger)taxonId {
    ExploreTaxonRealm *etr = [ExploreTaxonRealm objectForPrimaryKey:@(taxonId)];
    [self.delegate taxaSearchViewControllerChoseTaxon:etr];
}

#pragma mark - TableView helpers

- (void)showTaxon:(ExploreTaxonRealm *)taxon {
    TaxonDetailViewController *tdvc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle: nil] instantiateViewControllerWithIdentifier:@"TaxonDetailViewController"];
    tdvc.taxon = taxon;
    tdvc.delegate = self;
    [self.navigationController pushViewController:tdvc animated:YES];
}

- (UITableViewCell *)cellForUnknownTaxonInTableView:(UITableView *)tableView {
	ObsDetailTaxonCell *cell = (ObsDetailTaxonCell *)[tableView dequeueReusableCellWithIdentifier:@"TaxonCell"];
	
	FAKIcon *unknown = [FAKINaturalist speciesUnknownIconWithSize:44.0f];
	[unknown addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor]];
    [cell.taxonImageView cancelImageRequestOperation];
	[cell.taxonImageView setImage:[unknown imageWithSize:CGSizeMake(44, 44)]];
	cell.taxonImageView.layer.borderWidth = 0.0f;
	
	cell.taxonNameLabel.text = self.searchController.searchBar.text;
	cell.taxonNameLabel.textColor = [UIColor blackColor];
	cell.taxonNameLabel.font = [UIFont systemFontOfSize:cell.taxonNameLabel.font.pointSize];
	cell.taxonSecondaryNameLabel.text = @"";
	
	cell.accessoryType = UITableViewCellAccessoryNone;
	
	return cell;
}

- (UITableViewCell *)cellForTaxon:(ExploreTaxonRealm *)etr inTableView:(UITableView *)tableView {
    if (!etr) {
        return [self cellForUnknownTaxonInTableView:tableView];
    }
    
    ObsDetailTaxonCell *cell = (ObsDetailTaxonCell *)[tableView dequeueReusableCellWithIdentifier:@"TaxonCell"];
    
    
    UIImage *iconicTaxonImage = [[ImageStore sharedImageStore] iconicTaxonImageForName:etr.iconicTaxonName];
    if (etr.photoUrl) {
        [cell.taxonImageView setImageWithURL:etr.photoUrl
                            placeholderImage:iconicTaxonImage];
    } else {
        [cell.taxonImageView setImage:iconicTaxonImage];
    }
    cell.taxonImageView.layer.borderWidth = 1.0f;
    
    
    if (etr.commonName) {
        cell.taxonNameLabel.text = etr.commonName;
        cell.taxonSecondaryNameLabel.text = etr.scientificName;
        CGFloat pointSize = cell.taxonSecondaryNameLabel.font.pointSize;
        if (etr.rankLevel > 0 && etr.rankLevel <= 20) {
            cell.taxonSecondaryNameLabel.font = [UIFont italicSystemFontOfSize:pointSize];
        } else {
            cell.taxonSecondaryNameLabel.text = [NSString stringWithFormat:@"%@ %@",
                                                 [etr.rankName capitalizedString],
                                                 [etr scientificName]];
            cell.taxonSecondaryNameLabel.font = [UIFont systemFontOfSize:pointSize];
        }
    } else {
        cell.taxonNameLabel.text = etr.scientificName;
        cell.taxonSecondaryNameLabel.text = @"";
        CGFloat pointSize = cell.taxonNameLabel.font.pointSize;
        if (etr.rankLevel > 0 && etr.rankLevel <= 20) {
            cell.taxonNameLabel.font = [UIFont italicSystemFontOfSize:pointSize];
        } else {
            cell.taxonNameLabel.font = [UIFont systemFontOfSize:pointSize];
            cell.taxonNameLabel.text = [NSString stringWithFormat:@"%@ %@",
                                        [etr.rankName capitalizedString],
                                        [etr scientificName]];
        }
    }
    
    cell.accessoryType = UITableViewCellAccessoryDetailButton;
    
    return cell;
}

@end
