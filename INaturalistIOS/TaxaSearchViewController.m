//
//  TaxaSearchViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/30/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <MBProgressHUD/MBProgressHUD.h>
#import <SDWebImage/UIImageView+WebCache.h>

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

@implementation TaxaSearchViewController

#pragma mark - iNat API

#pragma mark - UIControl interactions

- (void)clickedAccessory:(id)sender event:(UIEvent *)event {
	NSArray *targetTaxa = self.taxaSearchController.searchResults;
	UITableView *tableView = self.searchDisplayController.searchResultsTableView;
	CGPoint currentTouchPosition = [event.allTouches.anyObject locationInView:tableView];
	NSIndexPath *indexPath = [tableView indexPathForRowAtPoint:currentTouchPosition];
	
	// be defensive
	if (indexPath) {		
		NSString *activeSearchText = self.searchDisplayController.searchBar.text;
		if (self.taxaSearchController.allowsFreeTextSelection && activeSearchText.length > 0 && indexPath.section == 0) {
			[self.delegate taxaSearchViewControllerChoseSpeciesGuess:activeSearchText];
			return;
		}

		ExploreTaxonRealm *etr;
		@try {
			// either of these paths could throw an exception
			// if something isn't found at this index path
			// in that case, silently do nothing
			etr = [targetTaxa objectAtIndex:indexPath.row];
		} @catch (NSException *e) { }   // silently do nothing
		
		if (etr) {
			[self showTaxon:etr];
		}
	}
}

- (IBAction)clickedCancel:(id)sender {
	[[self parentViewController] dismissViewControllerAnimated:YES
													completion:nil];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
	[self.navigationController popViewControllerAnimated:YES];
	//[[self parentViewController] dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIViewController lifecycle
- (void)viewDidLoad {
	[super viewDidLoad];
		
	// setup our search controller
	if (!self.taxaSearchController) {
		self.taxaSearchController = [[TaxaSearchController alloc] 
									 initWithSearchDisplayController:self.searchDisplayController];
		self.taxaSearchController.delegate = self;
		self.taxaSearchController.allowsFreeTextSelection = self.allowsFreeTextSelection;
	}
	
	[self.tableView registerNib:[UINib nibWithNibName:@"TaxonCell" bundle:nil] forCellReuseIdentifier:@"TaxonOneNameCell"];
	
	// show blank screen when empty
	self.tableView.tableFooterView = [UIView new];

	[self.searchDisplayController setActive:YES];	
	if (self.query && self.query.length > 0) {
		self.searchDisplayController.searchBar.text = self.query;
	}
	self.searchDisplayController.searchBar.delegate = self;
	[self.searchDisplayController.searchBar becomeFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateTaxaSearch];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateTaxaSearch];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	[self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	[self.tableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
	   atIndexPath:(NSIndexPath *)indexPath
	 forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath {
	
	switch (type) {
		case NSFetchedResultsChangeInsert:
			[self.tableView insertRowsAtIndexPaths:@[ newIndexPath ]
								  withRowAnimation:UITableViewRowAnimationAutomatic];
			break;
			
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteRowsAtIndexPaths:@[ indexPath ]
								  withRowAnimation:UITableViewRowAnimationAutomatic];
			break;
			
		case NSFetchedResultsChangeUpdate:
			[self.tableView reloadRowsAtIndexPaths:@[ indexPath ]
								  withRowAnimation:UITableViewRowAnimationNone];
			break;
			
		case NSFetchedResultsChangeMove:
			[self.tableView moveRowAtIndexPath:indexPath
								   toIndexPath:newIndexPath];
			break;
			
		default:
			break;
	}
}

#pragma mark - UITableViewDelegate

- (UITableViewCell *)cellForUnknownTaxonInTableView:(UITableView *)tableView {
	ObsDetailTaxonCell *cell = (ObsDetailTaxonCell *)[tableView dequeueReusableCellWithIdentifier:@"TaxonCell"];
	
	FAKIcon *unknown = [FAKINaturalist speciesUnknownIconWithSize:44.0f];
	[unknown addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor]];
	[cell.taxonImageView sd_cancelCurrentImageLoad];
	[cell.taxonImageView setImage:[unknown imageWithSize:CGSizeMake(44, 44)]];
	cell.taxonImageView.layer.borderWidth = 0.0f;
	
	cell.taxonNameLabel.text = self.searchDisplayController.searchBar.text;
	cell.taxonNameLabel.textColor = [UIColor blackColor];
	cell.taxonNameLabel.font = [UIFont systemFontOfSize:cell.taxonNameLabel.font.pointSize];
	cell.taxonSecondaryNameLabel.text = @"";
	
	return cell;
}

#pragma mark - Table view data source
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 60;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (void)showTaxon:(ExploreTaxonRealm *)taxon {
	TaxonDetailViewController *tdvc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle: nil] instantiateViewControllerWithIdentifier:@"TaxonDetailViewController"];
	tdvc.taxon = taxon;
	tdvc.delegate = self;
	[self.navigationController pushViewController:tdvc animated:YES];
}

#pragma mark - RecordSearchControllerDelegate
- (void)recordSearchControllerSelectedRecord:(id)record {
	// add the ID
    if ([record isKindOfClass:[ExploreTaxonRealm class]]) {
        ExploreTaxonRealm *etr = (ExploreTaxonRealm *)record;
        [self.delegate taxaSearchViewControllerChoseTaxon:etr];
    } else if (!record && [self.searchDisplayController.searchBar.text length] > 2) {
    	[self.delegate taxaSearchViewControllerChoseSpeciesGuess:self.searchDisplayController.searchBar.text];
    }
}

- (UITableViewCell *)recordSearchControllerCellForRecord:(NSObject *)record inTableView:(UITableView *)tableView {
	if (!record) {
		return [self cellForUnknownTaxonInTableView:tableView];
	}
	
	ExploreTaxonRealm *etr = (ExploreTaxonRealm *)record;
	ObsDetailTaxonCell *cell = (ObsDetailTaxonCell *)[tableView dequeueReusableCellWithIdentifier:@"TaxonCell"];
		
  	[cell.taxonImageView sd_cancelCurrentImageLoad];	
	UIImage *iconicTaxonImage = [[ImageStore sharedImageStore] iconicTaxonImageForName:etr.iconicTaxonName];
	if (etr.photoUrl) {
		[cell.taxonImageView sd_setImageWithURL:etr.photoUrl placeholderImage:iconicTaxonImage];
	} else {
		[cell.taxonImageView setImage:iconicTaxonImage];
	}
	cell.taxonImageView.layer.borderWidth = 1.0f;
	
	
	if (etr.commonName) {
		cell.taxonNameLabel.text = etr.commonName;
		cell.taxonSecondaryNameLabel.text = etr.scientificName;
		CGFloat pointSize = cell.taxonSecondaryNameLabel.font.pointSize;
		if (etr.isGenusOrLower) {
			cell.taxonSecondaryNameLabel.font = [UIFont italicSystemFontOfSize:pointSize];
		} else {
			cell.taxonSecondaryNameLabel.font = [UIFont systemFontOfSize:pointSize];
		}
	} else {
		cell.taxonNameLabel.text = etr.scientificName;
		cell.taxonSecondaryNameLabel.text = @"";
		CGFloat pointSize = cell.taxonNameLabel.font.pointSize;
		if (etr.isGenusOrLower) {
			cell.taxonNameLabel.font = [UIFont italicSystemFontOfSize:pointSize];
		} else {
			cell.taxonNameLabel.font = [UIFont systemFontOfSize:pointSize];
		}
	}
	
	cell.accessoryType = UITableViewCellAccessoryDetailButton;
	
	return cell;
}


- (void)recordSearchControllerClickedAccessoryForRecord:(id)record {
	if ([record isKindOfClass:[ExploreTaxonRealm class]]) {
		[self showTaxon:(ExploreTaxonRealm *)record];
	}
}

#pragma mark - TaxonDetailViewControllerDelegate
- (void)taxonDetailViewControllerClickedActionForTaxonId:(NSInteger)taxonId {
    RLMResults *results = [ExploreTaxonRealm objectsWhere:@"taxonId == %d", taxonId];
    if (results.count == 1) {
        ExploreTaxonRealm *etr = [results firstObject];
        [self.delegate taxaSearchViewControllerChoseTaxon:etr];
    }
}

@end
