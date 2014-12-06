//
//  TaxaSearchViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/30/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import "TaxaSearchViewController.h"
#import "ImageStore.h"
#import "TaxonPhoto.h"
#import "TaxonDetailViewController.h"
#import "Analytics.h"

@interface TaxaSearchViewController () <NSFetchedResultsControllerDelegate> {
    NSFetchedResultsController *fetchedResultsController;
}
@end

static const int TaxonCellImageTag = 1;
static const int TaxonCellTitleTag = 2;
static const int TaxonCellSubtitleTag = 3;

@implementation TaxaSearchViewController
@synthesize taxaSearchController = _taxaSearchController;
@synthesize taxon = _taxon;
@synthesize lastRequestAt = _lastRequestAt;
@synthesize delegate = _delegate;
@synthesize query = _query;

#pragma mark - iNat API

- (void)loadRemoteTaxaWithURL:(NSString *)url {
    
    // silently do nothing if we're offline
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        return;
    }
    
    // only notify modally if we're fetching these taza from scratch
    BOOL modal = ((id <NSFetchedResultsSectionInfo>)[fetchedResultsController sections][0]).numberOfObjects == 0;
    if (modal)
        [SVProgressHUD showWithStatus:NSLocalizedString(@"Loading...",nil)];
    
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:[url stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                                    usingBlock:^(RKObjectLoader *loader) {
                                                        
                                                        loader.objectMapping = [Taxon mapping];
                                                        
                                                        loader.onDidLoadObjects = ^(NSArray *objects) {
                                                            
                                                            // update timestamps on us and taxa objects
                                                            NSDate *now = [NSDate date];
                                                            self.lastRequestAt = now;
                                                            [objects enumerateObjectsUsingBlock:^(INatModel *o,
                                                                                                  NSUInteger idx,
                                                                                                  BOOL *stop) {
                                                                [o setSyncedAt:now];
                                                            }];
                                                            
                                                            // /taxa/{id}/children API endpoint is comprehensive.
                                                            // delete any child taxa that core data already had,
                                                            // that weren't returned from the API.
                                                            for (Taxon *t in fetchedResultsController.fetchedObjects) {
                                                                if (![objects containsObject:t]) {
                                                                    [t deleteEntity];
                                                                }
                                                            }
                                                            
                                                            // save into core data
                                                            NSError *saveError = nil;
                                                            [[[RKObjectManager sharedManager] objectStore] save:&saveError];
                                                            if (saveError) {
                                                                [SVProgressHUD showErrorWithStatus:saveError.localizedDescription];
                                                                return;
                                                            }
                                                            
                                                            // update the UI with the merged results
                                                            NSError *fetchError;
                                                            [fetchedResultsController performFetch:&fetchError];
                                                            if (fetchError) {
                                                                [SVProgressHUD showErrorWithStatus:fetchError.localizedDescription];
                                                                return;
                                                            }
                                                            
                                                            if (modal) {
                                                                if (objects.count > 0)
                                                                    [SVProgressHUD showSuccessWithStatus:nil];
                                                                else
                                                                    [SVProgressHUD showErrorWithStatus:nil];
                                                            }
                                                        };
                                                        
                                                        loader.onDidFailLoadWithError = ^(NSError *error) {
                                                            [SVProgressHUD showErrorWithStatus:error.localizedDescription];
                                                        };
                                                        
                                                        loader.onDidFailLoadWithError = ^(NSError *error) {
                                                            [SVProgressHUD showErrorWithStatus:error.localizedDescription];
                                                        };
                                            
                                                    }];
}

#pragma mark - UIControl interactions

- (void)clickedAccessory:(id)sender event:(UIEvent *)event {
    UITableView *targetTableView;
    NSArray *targetTaxa;
    if (self.searchDisplayController.active) {
        targetTableView = self.searchDisplayController.searchResultsTableView;
        targetTaxa = self.taxaSearchController.searchResults;
    } else {
        targetTableView = self.tableView;
    }
    CGPoint currentTouchPosition = [event.allTouches.anyObject locationInView:targetTableView];
    NSIndexPath *indexPath = [targetTableView indexPathForRowAtPoint:currentTouchPosition];
    
    // be defensive
    if (indexPath) {
        
        Taxon *t;
        
        @try {
            // either of these paths could throw an exception
            // if something isn't found at this index path
            // in that case, silently do nothing
            if (self.searchDisplayController.active) {
                t = [targetTaxa objectAtIndex:indexPath.row];
            } else {
                t = [fetchedResultsController objectAtIndexPath:indexPath];
            }
        } @catch (NSException *e) {

        }
        
        if (t) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(taxaSearchViewControllerChoseTaxon:)]) {
                [self.delegate taxaSearchViewControllerChoseTaxon:t];
            } else {
                [self showTaxon:t];
            }
        }
    }
}

- (IBAction)clickedCancel:(id)sender {
    [[self parentViewController] dismissViewControllerAnimated:YES
                                                    completion:nil];
}

#pragma mark - UIViewController lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // NSFetchedResultsController request for these taxa
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Taxon"];
    
    // sort by common name, if available
    request.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"defaultName" ascending:YES] ];
    
    // setup the request predicate
    if (self.taxon) {
        // children of self.taxon, using ancestry
        NSString *queryAncestry;
        if (self.taxon.ancestry && self.taxon.ancestry.length > 0) {
            queryAncestry = [NSString stringWithFormat:@"%@/%d", self.taxon.ancestry, self.taxon.recordID.intValue];
        } else {
            queryAncestry = [NSString stringWithFormat:@"%d", self.taxon.recordID.intValue];
        }
        request.predicate = [NSPredicate predicateWithFormat:@"ancestry == %@", queryAncestry];
    } else {
        [request setPredicate:[NSPredicate predicateWithFormat:@"isIconic == YES"]];
    }
    
    // setup our fetched results controller
    fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                   managedObjectContext:[NSManagedObjectContext defaultContext]
                                                                     sectionNameKeyPath:nil
                                                                              cacheName:nil];
    // update our tableview based on changes in the fetched results
    fetchedResultsController.delegate = self;
    
    // perform the iniital local fetch
    NSError *fetchError;
    [fetchedResultsController performFetch:&fetchError];
    if (fetchError) {
        [SVProgressHUD showErrorWithStatus:fetchError.localizedDescription];
        NSLog(@"FETCH ERROR: %@", fetchError);
    }
    
    // setup our search controller
    if (!self.taxaSearchController) {
        self.taxaSearchController = [[TaxaSearchController alloc] 
                                     initWithSearchDisplayController:self.searchDisplayController];
        self.taxaSearchController.delegate = self;
    }
    
    // perform the remote fetch for these taxa
    if (self.taxon) {
        // fetch children
        self.navigationItem.title = self.taxon.defaultName;
        [self loadRemoteTaxaWithURL:[NSString stringWithFormat:@"/taxa/%d/children", self.taxon.recordID.intValue]];
    } else {
        // iconic taxa fetch
        if ([((id <NSFetchedResultsSectionInfo>)[fetchedResultsController sections].firstObject) numberOfObjects] < 10 && !self.lastRequestAt) {
            [self loadRemoteTaxaWithURL:@"/taxa"];
        }
    }
    
    // configure this tableview
    [self.tableView registerNib:[UINib nibWithNibName:@"TaxonOneNameTableViewCell" bundle:nil] forCellReuseIdentifier:@"TaxonOneNameCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"TaxonTwoNameTableViewCell" bundle:nil] forCellReuseIdentifier:@"TaxonTwoNameCell"];
    
    // This is a weird way to trick the underlying table view NOT to show any
    // rows when there's no data. Without this you will sometimes see overlapping
    // cell borders on top of the search results
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    self.tableView.tableFooterView = view;
    
    if (self.query && self.query.length > 0) {
        [self.searchDisplayController setActive:YES];
        self.searchDisplayController.searchBar.text = self.query;
    }
    
    if (self.hidesDoneButton)
        self.navigationItem.rightBarButtonItem = nil;
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
- (UITableViewCell *)cellForTaxon:(Taxon *)t inTableView:(UITableView *)tableView {
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
    [addButton setTitle:NSLocalizedString(@"Add",nil) forState:UIControlStateNormal];
    [addButton setTitle:NSLocalizedString(@"Add",nil) forState:UIControlStateHighlighted];
    addButton.titleLabel.textColor = [UIColor whiteColor];
    addButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [addButton addTarget:self action:@selector(clickedAccessory:event:) forControlEvents:UIControlEventTouchUpInside];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.accessoryView = addButton;
        
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:TaxonCellImageTag];
    [imageView sd_cancelCurrentImageLoad];
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:TaxonCellTitleTag];
    titleLabel.text = t.defaultName;
    UIImage *iconicTaxonImage = [[ImageStore sharedImageStore] iconicTaxonImageForName:t.iconicTaxonName];
    imageView.image = iconicTaxonImage;
    
    TaxonPhoto *tp = [t.taxonPhotos firstObject];
    if (tp) {
        [imageView sd_setImageWithURL:[NSURL URLWithString:tp.squareURL]
                     placeholderImage:iconicTaxonImage];
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
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 54;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Taxon *t = (Taxon *)[fetchedResultsController objectAtIndexPath:indexPath];
    return [self cellForTaxon:t inTableView:tableView];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Taxon *t = (Taxon *)[fetchedResultsController objectAtIndexPath:indexPath];
    [self showTaxon:t];
}

#pragma mark - Show Taxon

- (void)showTaxon:(Taxon *)taxon inNavigationController:(UINavigationController *)navigationController {
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
        // propogate the "hides done button" state through the stack
        tsvc.hidesDoneButton = self.hidesDoneButton;
        vc = tsvc;
    }
    [navigationController pushViewController:vc animated:YES];
}

- (void)showTaxon:(Taxon *)taxon {
    [self showTaxon:taxon inNavigationController:self.navigationController];
}


#pragma mark - RecordSearchControllerDelegate
- (void)recordSearchControllerSelectedRecord:(id)record {
    UINavigationController *navigationController = self.navigationController;
    [navigationController popToRootViewControllerAnimated:NO];
    [self showTaxon:record inNavigationController:navigationController];
}

- (UITableViewCell *)recordSearchControllerCellForRecord:(NSObject *)record inTableView:(UITableView *)tableView {
    return [self cellForTaxon:(Taxon *)record inTableView:tableView];
}

#pragma mark - TaxonDetailViewControllerDelegate
- (void)taxonDetailViewControllerClickedActionForTaxon:(Taxon *)taxon {
    if (self.delegate && [self.delegate respondsToSelector:@selector(taxaSearchViewControllerChoseTaxon:)]) {
        [self.delegate performSelector:@selector(taxaSearchViewControllerChoseTaxon:) withObject:taxon];
    }
}

@end
