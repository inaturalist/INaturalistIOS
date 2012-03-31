//
//  TaxaSearchController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/30/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Three20/Three20.h>
#import "TaxaSearchController.h"
#import "Taxon.h"
#import "TaxonPhoto.h"
#import "ImageStore.h"

static const int TaxonCellImageTag = 1;
static const int TaxonCellTitleTag = 2;
static const int TaxonCellSubtitleTag = 3;

@implementation TaxaSearchController
- (id)initWithSearchDisplayController:(UISearchDisplayController *)searchDisplayController
{
    self = [super initWithSearchDisplayController:searchDisplayController];
    if (self) {
        self.model = Taxon.class;
        self.searchURL = @"/taxa/search?q=%@";
    }
    return self;
}

- (NSPredicate *)predicateForQuery:(NSString *)query
{
    return [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@ OR defaultName CONTAINS[cd] %@", query, query];
}

#pragma mark - UISearchDisplayControllerDelegate
- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView
{
    [tableView registerNib:[UINib nibWithNibName:@"TaxonOneNameTableViewCell" bundle:nil] forCellReuseIdentifier:@"TaxonOneNameCell"];
    [tableView registerNib:[UINib nibWithNibName:@"TaxonTwoNameTableViewCell" bundle:nil] forCellReuseIdentifier:@"TaxonTwoNameCell"];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
}

@end
