//
//  TaxaSearchController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/30/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "TaxaSearchController.h"
#import "Taxon.h"
#import "TaxonPhoto.h"
#import "ImageStore.h"

@implementation TaxaSearchController
- (id)initWithSearchDisplayController:(UISearchDisplayController *)searchDisplayController
{
    self = [super initWithSearchDisplayController:searchDisplayController];
    if (self) {
        self.model = Taxon.class;
        NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
        NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
        self.searchURL = [NSString stringWithFormat:@"/taxa/search?locale=%@-%@&q=%%@", language, countryCode];
    }
    return self;
}

- (NSPredicate *)predicateForQuery:(NSString *)query
{
    query = [query stringByReplacingOccurrencesOfString:@" " withString:@"*"];
    query = [query stringByReplacingOccurrencesOfString:@"-" withString:@"*"];
    query = [NSString stringWithFormat:@"*%@*", query];
    return [NSPredicate predicateWithFormat:@"name LIKE[cd] %@ OR defaultName LIKE[cd] %@", query, query];
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
