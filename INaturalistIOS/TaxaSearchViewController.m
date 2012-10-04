//
//  TaxaSearchViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/30/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Three20/Three20.h>
#import "TaxaSearchViewController.h"
#import "ImageStore.h"
#import "TaxonPhoto.h"
#import "TaxonDetailViewController.h"
#import "DejalActivityView.h"

static const int TaxonCellImageTag = 1;
static const int TaxonCellTitleTag = 2;
static const int TaxonCellSubtitleTag = 3;

@implementation TaxaSearchViewController
@synthesize taxaSearchController = _taxaSearchController;
@synthesize taxon = _taxon;
@synthesize taxa = _taxa;
@synthesize lastRequestAt = _lastRequestAt;
@synthesize delegate = _delegate;
@synthesize query = _query;

- (void)loadData
{
    if (self.taxon) {
        self.taxa = [NSMutableArray arrayWithArray:self.taxon.children];
        
        if (self.lastRequestAt) {
            // delete children that didn't come down in the last request.  Children endpoint should be comprehensive.
            NSMutableArray *taxaToDelete = [[NSMutableArray alloc] init];
            for (Taxon *t in self.taxa) {
                if ([self.lastRequestAt timeIntervalSinceDate:t.syncedAt] > 0 && t.listedTaxa.count == 0) {
                    [taxaToDelete addObject:t];
                }
            }
            for (Taxon *t in taxaToDelete) {
                [self.taxa removeObject:t];
                [t deleteEntity];
            }
            NSError *error = nil;
            [[[RKObjectManager sharedManager] objectStore] save:&error];
        } else {
            [self performSelector:@selector(loadRemoteTaxaWithURL:) 
                       withObject:[NSString stringWithFormat:@"/taxa/%d/children", self.taxon.recordID.intValue] 
                       afterDelay:0.5];
        }
    } else {
        NSFetchRequest *request = [Taxon fetchRequest];
        [request setPredicate:[NSPredicate predicateWithFormat:@"isIconic == YES"]];
        [request setSortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"ancestry" ascending:YES]]];
        self.taxa = [NSMutableArray arrayWithArray:[Taxon objectsWithFetchRequest:request]];
        if (self.taxa.count == 0 && !self.lastRequestAt) {
            [self performSelector:@selector(loadRemoteTaxaWithURL:) 
                       withObject:@"/taxa"
                       afterDelay:0.5];
        }
    }
}

- (void)loadRemoteTaxaWithURL:(NSString *)url
{
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        return;
    }
    BOOL modal = self.taxa.count == 0;
    if (modal) {
        [DejalBezelActivityView activityViewForView:self.tableView withLabel:@"Loading..."];
    }
    
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:[url stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                                         usingBlock:^(RKObjectLoader *loader) {
        loader.delegate = self;
        loader.objectMapping = [Taxon mapping];
    }];
}

- (void)clickedAccessory:(id)sender event:(UIEvent *)event
{
    UITableView *targetTableView;
    NSArray *targetTaxa;
    if (self.searchDisplayController.active) {
        targetTableView = self.searchDisplayController.searchResultsTableView;
        targetTaxa = self.taxaSearchController.searchResults;
    } else {
        targetTableView = self.tableView;
        targetTaxa = self.taxa;
    }
    CGPoint currentTouchPosition = [event.allTouches.anyObject locationInView:targetTableView];
    NSIndexPath *indexPath = [targetTableView indexPathForRowAtPoint:currentTouchPosition];
    Taxon *t = [targetTaxa objectAtIndex:indexPath.row];
    if (self.delegate && [self.delegate respondsToSelector:@selector(taxaSearchViewControllerChoseTaxon:)]) {
        [self.delegate performSelector:@selector(taxaSearchViewControllerChoseTaxon:) withObject:t];
    } else {
        [self showTaxon:t];
    }
}

#pragma mark - lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    if (!self.taxaSearchController) {
        self.taxaSearchController = [[TaxaSearchController alloc] 
                                     initWithSearchDisplayController:self.searchDisplayController];
        self.taxaSearchController.delegate = self;
    }
    
    if (self.taxon) {
        self.navigationItem.title = self.taxon.defaultName;
    }
    
    if (self.query && self.query.length > 0) {
        [self.searchDisplayController setActive:YES];
        self.searchDisplayController.searchBar.text = self.query;
    }
    
    [self.tableView registerNib:[UINib nibWithNibName:@"TaxonOneNameTableViewCell" bundle:nil] forCellReuseIdentifier:@"TaxonOneNameCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"TaxonTwoNameTableViewCell" bundle:nil] forCellReuseIdentifier:@"TaxonTwoNameCell"];
    
    [self loadData];
}

#pragma mark - UITableViewDelegate
- (UITableViewCell *)cellForTaxon:(Taxon *)t inTableView:(UITableView *)tableView
{
    NSString *cellIdentifier = [t.name isEqualToString:t.defaultName] ? @"TaxonOneNameCell" : @"TaxonTwoNameCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    UIButton *addButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 35)];
    [addButton setBackgroundImage:[UIImage imageNamed:@"add_button"] 
                         forState:UIControlStateNormal];
    [addButton setBackgroundImage:[UIImage imageNamed:@"add_button_highlight"] 
                         forState:UIControlStateHighlighted];
    [addButton setTitle:@"Add" forState:UIControlStateNormal];
    [addButton setTitle:@"Add" forState:UIControlStateHighlighted];
    addButton.titleLabel.textColor = [UIColor whiteColor];
    addButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [addButton addTarget:self action:@selector(clickedAccessory:event:) forControlEvents:UIControlEventTouchUpInside];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.accessoryView = addButton;
    
    TTImageView *imageView = (TTImageView *)[cell viewWithTag:TaxonCellImageTag];
    [imageView unsetImage];
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:TaxonCellTitleTag];
    titleLabel.text = t.defaultName;
    imageView.defaultImage = [[ImageStore sharedImageStore] iconicTaxonImageForName:t.iconicTaxonName];
    TaxonPhoto *tp = [t.taxonPhotos firstObject];
    if (tp) {
        imageView.urlPath = tp.squareURL;
    } else {
        imageView.urlPath = nil;
    }
    if ([t.name isEqualToString:t.defaultName]) {
        if (t.rankLevel.intValue >= 30) {
            titleLabel.font = [UIFont boldSystemFontOfSize:titleLabel.font.pointSize];
        } else {
            titleLabel.font = [UIFont fontWithName:@"Helvetica-BoldOblique" size:titleLabel.font.pointSize];
        }
    } else {
        UILabel *subtitleLabel = (UILabel *)[cell viewWithTag:TaxonCellSubtitleTag];
        if (t.isGenusOrLower) {
            subtitleLabel.text = t.name;
            subtitleLabel.font = [UIFont italicSystemFontOfSize:subtitleLabel.font.pointSize];
        } else {
            subtitleLabel.text = [NSString stringWithFormat:@"%@ %@", [t.rank capitalizedString], t.name];
            subtitleLabel.font = [UIFont systemFontOfSize:subtitleLabel.font.pointSize];
        }
    }
    
    return cell;
}

#pragma mark - Table view data source
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.taxa.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Taxon *t = [self.taxa objectAtIndex:[indexPath row]];
    return [self cellForTaxon:t inTableView:tableView];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Taxon *t = [self.taxa objectAtIndex:indexPath.row];
    [self showTaxon:t];
}

- (void)showTaxon:(Taxon *)taxon inNavigationController:(UINavigationController *)navigationController
{
    UIViewController *vc;
    if (taxon.isSpeciesOrLower) {
        TaxonDetailViewController *tdvc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:NULL] 
                                           instantiateViewControllerWithIdentifier:@"TaxonDetailViewController"];
        tdvc.taxon = taxon;
        tdvc.delegate = self;
        vc = tdvc;
    } else {
        TaxaSearchViewController *tsvc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:NULL] 
                                          instantiateViewControllerWithIdentifier:@"TaxaSearchViewController"];
        tsvc.taxon = taxon;
        tsvc.delegate = self.delegate;
        vc = tsvc;
    }
    [navigationController pushViewController:vc animated:YES];
}

- (void)showTaxon:(Taxon *)taxon
{
    [self showTaxon:taxon inNavigationController:self.navigationController];
}

- (IBAction)clickedCancel:(id)sender {
    [[self parentViewController] dismissViewControllerAnimated:YES 
                                                    completion:nil];
}

#pragma mark - RKObjectLoaderDelegate
- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects
{
    NSDate *now = [NSDate date];
    self.lastRequestAt = now;
    INatModel *o;
    for (int i = 0; i < objects.count; i++) {
        o = [objects objectAtIndex:i];
        [o setSyncedAt:now];
    }
    NSError *error = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
    [self loadData];
    [self.tableView reloadData];
    [DejalBezelActivityView removeViewAnimated:YES];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error
{
    [DejalBezelActivityView removeViewAnimated:YES];
}

#pragma mark - RecordSearchControllerDelegate
- (void)recordSearchControllerSelectedRecord:(id)record
{
    UINavigationController *navigationController = self.navigationController;
    [navigationController popToRootViewControllerAnimated:NO];
    [self showTaxon:record inNavigationController:navigationController];
}

- (UITableViewCell *)recordSearchControllerCellForRecord:(NSObject *)record inTableView:(UITableView *)tableView
{
    return [self cellForTaxon:(Taxon *)record inTableView:tableView];
}

#pragma mark - TaxonDetailViewControllerDelegate
- (void)taxonDetailViewControllerClickedActionForTaxon:(Taxon *)taxon
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(taxaSearchViewControllerChoseTaxon:)]) {
        [self.delegate performSelector:@selector(taxaSearchViewControllerChoseTaxon:) withObject:taxon];
    }
}

@end
