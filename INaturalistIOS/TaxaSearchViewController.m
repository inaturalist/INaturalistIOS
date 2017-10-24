//
//  TaxaSearchViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/30/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

@import AVFoundation;

#import <MBProgressHUD/MBProgressHUD.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <AFNetworking/AFNetworking.h>
#import <FontAwesomeKit/FAKIonIcons.h>

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
#import "ObservationAPI.h"
#import "NSURL+INaturalist.h"
#import "TaxonSuggestionCell.h"
#import "UIColor+INaturalist.h"
#import "ExploreTaxonScore.h"
#import "ObservationPhoto.h"
#import "ObserverCount.h"
#import "IdentifierCount.h"
#import "ExploreUser.h"
#import "UIImage+INaturalist.h"

#define MIN_CHARS_TAXA_SEARCH 3

@interface TaxaSearchViewController () <UISearchResultsUpdating, UISearchControllerDelegate, UITableViewDelegate, UITableViewDataSource>
@property UISearchController *searchController;
@property RLMResults <ExploreTaxonRealm *> *searchResults;
@property NSArray <ExploreTaxonScore *> *scores;
@property NSArray <NSString *> *creditNames;
@property ExploreTaxonRealm *commonAncestor;
@property BOOL showingSuggestions;

@property IBOutlet UIImageView *headerImageView;
@property IBOutlet UITableView *tableView;
@property IBOutlet NSLayoutConstraint *headerHeightConstraint;
@property IBOutlet UIView *loadingView;
@property IBOutlet UILabel *statusLabel;
@property IBOutlet UIActivityIndicatorView *loadingSpinner;
@property IBOutlet UIView *suggestionHeaderView;
@end

@implementation TaxaSearchViewController


#pragma mark - UISearchControllerDelegate

- (void)willPresentSearchController:(UISearchController *)searchController {
    self.headerHeightConstraint.constant = 0.0f;
    [self.view setNeedsLayout];
    
    self.showingSuggestions = NO;
    [self.tableView reloadData];
    [searchController.searchBar becomeFirstResponder];
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    // if the we aren't showing suggestions for any reason, if the user
    // dismisses the search controller then we should just totally bail
    // on taxa search
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kINatSuggestionsPrefKey]) {
        // no suggestions without permission
        [self.delegate taxaSearchViewControllerCancelled];
    } else if (self.imageToClassify || (self.observationToClassify && self.observationToClassify.sortedObservationPhotos.count > 0)) {
        // switch back to suggestions mode
        self.headerHeightConstraint.constant = 132.0f;
        [self.view setNeedsLayout];
        
        self.showingSuggestions = YES;
        [self.tableView reloadData];
        if (self.scores.count == 0 && !self.commonAncestor) {
            self.tableView.backgroundView.hidden = NO;
        }
    } else {
        // no suggestions without a photo
        [self.delegate taxaSearchViewControllerCancelled];
    }
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

- (ObservationAPI *)obsApi {
    static ObservationAPI *_api = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _api = [[ObservationAPI alloc] init];
    });
    return _api;
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    if (self.showingSuggestions) {
        return;
    }
    
    self.tableView.backgroundView.hidden = TRUE;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
    
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

- (IBAction)clickedCancel:(UIControl *)control {
    [self.delegate taxaSearchViewControllerCancelled];
}

#pragma mark - UIViewController lifecycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.coordinate = kCLLocationCoordinate2DInvalid;
    }
    return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];

    
    // setup the search controller
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = false;
    self.searchController.searchBar.placeholder = NSLocalizedString(@"Look up a species by name",
                                                                    @"placeholder text for taxon search bar");
    self.searchController.delegate = self;
    self.definesPresentationContext = YES;
    // user prefs determine autocorrection/spellcheck behavior of the species guess field
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kINatAutocompleteNamesPrefKey]) {
        [self.searchController.searchBar setAutocorrectionType:UITextAutocorrectionTypeYes];
        [self.searchController.searchBar setSpellCheckingType:UITextSpellCheckingTypeDefault];
    } else {
        [self.searchController.searchBar setAutocorrectionType:UITextAutocorrectionTypeNo];
        [self.searchController.searchBar setSpellCheckingType:UITextSpellCheckingTypeNo];
    }

    // setup the table view
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerNib:[UINib nibWithNibName:@"TaxonCell" bundle:nil]
         forCellReuseIdentifier:@"TaxonCell"];
    // don't show the extra lines when no tv rows
    self.tableView.tableFooterView = [UIView new];
    
    // design tweaks for suggestions header
    self.suggestionHeaderView.layer.borderWidth = 0.5f;
    self.suggestionHeaderView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.headerImageView.layer.cornerRadius = 1.0f;
    self.headerImageView.layer.borderWidth = 1.0f;
    self.headerImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    // we're shrinking a decently sized image down to a small square,
    // so provide a minification filter that's easier on the eyes and
    // produces fewer resizing artifacts
    self.headerImageView.layer.minificationFilter = kCAFilterTrilinear;
    self.headerImageView.layer.minificationFilterBias = 0.1;


    NSDate *beforeSuggestions = [NSDate date];
    
    // this is the callback for our suggestions api call
    INatAPISuggestionsCompletionHandler done = ^(NSArray *suggestions, ExploreTaxon *parent, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [[Analytics sharedClient] event:kAnalyticsEventSuggestionsFailed
                                 withProperties:@{
                                                  @"error": error.localizedDescription,
                                                  }];
                self.tableView.backgroundView = self.loadingView;
                self.loadingSpinner.hidden = YES;
                self.statusLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Cannot load suggestions: %@",
                                                                                     @"error when loading suggestions. %@ is the error message"),
                                         error.localizedDescription];
            } else {
                if (self.imageToClassify) {
                    [[Analytics sharedClient] logMetric:kAnalyticsEventSuggestionsImageGauge
                                                  value:@(fabs([beforeSuggestions timeIntervalSinceNow]))];
                } else {
                    [[Analytics sharedClient] logMetric:kAnalyticsEventSuggestionsObservationGauge
                                                  value:@(fabs([beforeSuggestions timeIntervalSinceNow]))];
                }
                
                RLMRealm *realm = [RLMRealm defaultRealm];
                [realm beginWriteTransaction];
                if (parent) {
                    ExploreTaxonRealm *etr = [[ExploreTaxonRealm alloc] initWithMantleModel:parent];
                    [realm addOrUpdateObject:etr];
                    self.commonAncestor = etr;
                }
                
                for (ExploreTaxonScore *ets in suggestions) {
                    ExploreTaxonRealm *etr = [[ExploreTaxonRealm alloc] initWithMantleModel:ets.exploreTaxon];
                    [realm addOrUpdateObject:etr];
                }
                
                [realm commitWriteTransaction];
                self.scores = suggestions;

                [[Analytics sharedClient] event:kAnalyticsEventSuggestionsLoaded
                                 withProperties:@{
                                                  @"WithAncestor": self.commonAncestor ? @"Yes": @"No",
                                                  @"Ancestor": self.commonAncestor ? self.commonAncestor.scientificName : @"None",
                                                  @"AncestorRank": self.commonAncestor ? self.commonAncestor.rankName : @"None",
                                                  @"TopTaxon": self.scores.firstObject.exploreTaxon.scientificName,
                                                  @"TopTaxonScore": @(self.scores.firstObject.combinedScore),
                                                  }];

                
                // remove the loading view
                self.tableView.backgroundView = nil;
                [self.tableView reloadData];
                
                NSMutableArray *taxaIds = [NSMutableArray array];
                if (self.commonAncestor) {
                    [taxaIds addObject:@(self.commonAncestor.taxonId)];
                }
                for (ExploreTaxonScore *ets in self.scores) {
                    [taxaIds addObject:@(ets.exploreTaxon.taxonId)];
                }
                
                if (arc4random_uniform(2) == 1) {
                    // load observers
                    [[self obsApi] topObserversForTaxaIds:taxaIds handler:^(NSArray *results, NSInteger count, NSError *error) {
                        NSMutableArray <NSString *> *credits = [NSMutableArray array];
                        for (ObserverCount *oc in results) {
                            if (oc.observer.name && oc.observer.name.length > 0) {
                                [credits addObject:oc.observer.name];
                            } else {
                                [credits addObject:oc.observer.login];
                            }
                        }
                        self.creditNames = [NSArray arrayWithArray:credits];
                        [self.tableView reloadData];
                    }];
                } else {
                    [[self obsApi] topIdentifiersForTaxaIds:taxaIds handler:^(NSArray *results, NSInteger count, NSError *error) {
                        NSMutableArray <NSString *> *credits = [NSMutableArray array];
                        for (IdentifierCount *ic in results) {
                            if (ic.identifier.name && ic.identifier.name.length > 0) {
                                [credits addObject:ic.identifier.name];
                            } else {
                                [credits addObject:ic.identifier.login];
                            }
                        }
                        self.creditNames = [NSArray arrayWithArray:credits];
                        [self.tableView reloadData];
                    }];

                }
                
            }
        });
    };
    
    if (self.hidesDoneButton) {
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kINatSuggestionsPrefKey]) {
        // no suggestions without permission
        [[Analytics sharedClient] event:kAnalyticsEventLoadTaxaSearch
                         withProperties:@{
                                          @"Suggestions": @"No",
                                          @"Reason": @"No Permissions",
                                          }];
        [self showNoSuggestions];
    } else if (self.imageToClassify) {
        [[Analytics sharedClient] event:kAnalyticsEventLoadTaxaSearch
                         withProperties:@{
                                          @"Suggestions": @"Yes",
                                          @"Source": @"Local Image",
                                          @"Coordinate": CLLocationCoordinate2DIsValid(self.coordinate) ? @"Yes" : @"No",
                                          @"Date": self.observedOn ? @"Yes" : @"No",
                                          }];
        [self loadAndShowImageSuggestionsWithCompletion:done];
    } else if (self.observationToClassify && self.observationToClassify.sortedObservationPhotos.count > 0) {
        [[Analytics sharedClient] event:kAnalyticsEventLoadTaxaSearch
                         withProperties:@{
                                          @"Suggestions": @"Yes",
                                          @"Source": @"Observation",
                                          @"Coordinate": CLLocationCoordinate2DIsValid(self.coordinate) ? @"Yes" : @"No",
                                          @"Date": self.observedOn ? @"Yes" : @"No",
                                          }];
        [self loadAndShowObservationSuggestionsWithCompletion:done];
    } else {
        // no suggestions without a photo
        [[Analytics sharedClient] event:kAnalyticsEventLoadTaxaSearch
                         withProperties:@{
                                          @"Suggestions": @"No",
                                          @"Reason": @"No Photo",
                                          }];
        [self showNoSuggestions];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!self.showingSuggestions) {
        // have to enqueue this, otherwise it's too early to have
        // the searchBar -becomeFirstResponder, even in -viewDidAppear:
        dispatch_async(dispatch_get_main_queue(), ^{
            // start the search UI right away
            [self.searchController setActive:YES];
            [self.searchController.searchBar becomeFirstResponder];
        });
    }
}

- (void)loadAndShowImageSuggestionsWithCompletion:(INatAPISuggestionsCompletionHandler)done {
    self.showingSuggestions = YES;
    self.headerImageView.image = [self imageToClassify];
    self.tableView.backgroundView = self.loadingView;
    [[self api] suggestionsForImage:self.imageToClassify
                           location:self.coordinate
                               date:self.observedOn
                            handler:done];

}

- (void)loadAndShowObservationSuggestionsWithCompletion:(INatAPISuggestionsCompletionHandler)done {
    self.showingSuggestions = YES;
    ObservationPhoto *op = [[self.observationToClassify sortedObservationPhotos] firstObject];
    [self.headerImageView setImageWithURL:[op squarePhotoUrl]];
    self.tableView.backgroundView = self.loadingView;
    [[self api] suggestionsForObservationId:self.observationToClassify.inatRecordId
                                    handler:done];
}

- (void)showNoSuggestions {
    self.showingSuggestions = NO;
    self.headerHeightConstraint.constant = 0.0f;
    // if the query field is pre-populated with a placeholder,
    // then search for it automatically.
    if (self.query && self.query.length > 0) {
        self.searchController.searchBar.text = self.query;
    }
}


#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self showingSuggestions]) {
        TaxonSuggestionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"suggestion"
                                                                    forIndexPath:indexPath];
        
        ExploreTaxonScore *ts = nil;
        id <TaxonVisualization> taxon = nil;
        if (indexPath.section == 0 && self.commonAncestor) {
            taxon = self.commonAncestor;
        } else {
            ts = [self.scores objectAtIndex:indexPath.item];
            taxon = [ts exploreTaxon];
        }
        
        if (ts) {
            NSString *reason = @"";
            if (ts.visionScore > 0 && ts.frequencyScore > 0) {
                reason = NSLocalizedString(@"Visually Similar / Seen Nearby", @"basis for a species suggestion");
            } else if (ts.visionScore > 0) {
                reason = NSLocalizedString(@"Visually Similar", @"basis for a species suggestion");
            } else if (ts.frequencyScore > 0) {
                reason = NSLocalizedString(@"Seen Nearby", @"basis for a suggestion");
            }
            cell.comment.text = reason;
        } else {
            cell.comment.text = nil;
        }
        
        UIImage *iconicTaxonImage = [[ImageStore sharedImageStore] iconicTaxonImageForName:taxon.iconicTaxonName];
        if (taxon.photoUrl) {
            [cell.image setImageWithURL:taxon.photoUrl
                       placeholderImage:iconicTaxonImage];
        } else {
            [cell.image setImage:iconicTaxonImage];
        }
        
        if (taxon.commonName) {
            cell.commonName.text = taxon.commonName;
            cell.scientificName.text = taxon.scientificName;
            CGFloat pointSize = cell.scientificName.font.pointSize;
            if (taxon.rankLevel > 0 && taxon.rankLevel <= 20) {
                cell.scientificName.font = [UIFont italicSystemFontOfSize:pointSize];
            } else {
                cell.scientificName.text = [NSString stringWithFormat:@"%@ %@",
                                            [taxon.rankName capitalizedString],
                                            [taxon scientificName]];
                cell.scientificName.font = [UIFont systemFontOfSize:pointSize];
            }
        } else {
            cell.commonName.text = taxon.scientificName;
            cell.scientificName.text = @"";
            CGFloat pointSize = cell.commonName.font.pointSize;
            if (taxon.rankLevel > 0 && taxon.rankLevel <= 20) {
                cell.commonName.font = [UIFont italicSystemFontOfSize:pointSize];
            } else {
                cell.commonName.font = [UIFont systemFontOfSize:pointSize];
                cell.commonName.text = [NSString stringWithFormat:@"%@ %@",
                                        [taxon.rankName capitalizedString],
                                        [taxon scientificName]];
            }
        }

        
        return cell;
    }
    
    if (self.allowsFreeTextSelection && indexPath.section == 1) {
        return [self cellForUnknownTaxonInTableView:tableView];
    } else {
        ExploreTaxonRealm *etr = [self.searchResults objectAtIndex:indexPath.item];
        return [self cellForTaxon:etr inTableView:tableView];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if ([self showingSuggestions]) {
        if (indexPath.section == 0 && self.commonAncestor) {
            [[Analytics sharedClient] event:kAnalyticsEventShowTaxonDetails
                             withProperties:@{
                                              @"Suggestions": @"Yes",
                                              @"Common Ancestor": @"Yes",
                                              }];
            [self showTaxonId:self.commonAncestor.taxonId];
        } else {
            ExploreTaxon *taxon = [[self.scores objectAtIndex:indexPath.item] exploreTaxon];
            [[Analytics sharedClient] event:kAnalyticsEventShowTaxonDetails
                             withProperties:@{
                                              @"Suggestions": @"Yes",
                                              @"Common Ancestor": @"No",
                                              }];
            [self showTaxonId:taxon.taxonId];
        }
    } else {
        if (self.searchResults.count > 0 && indexPath.section == 0) {
            ExploreTaxonRealm *taxon = [self.searchResults objectAtIndex:indexPath.item];
            [[Analytics sharedClient] event:kAnalyticsEventShowTaxonDetails
                             withProperties:@{
                                              @"Suggestions": @"No",
                                              }];
            [self showTaxonId:taxon.taxonId];
        } else {
            // do nothing
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self showingSuggestions]) {
        if (indexPath.section == 0 && self.commonAncestor) {
            [[Analytics sharedClient] event:kAnalyticsEventChoseTaxon
                             withProperties:@{
                                              @"IsTaxon": @"Yes",
                                              @"Suggestions": @"Yes",
                                              @"Common Ancestor": @"Yes",
                                              @"Via": @"List",
                                              }];
            [self.delegate taxaSearchViewControllerChoseTaxon:self.commonAncestor
                                              chosenViaVision:YES];
        } else {
            [[Analytics sharedClient] event:kAnalyticsEventChoseTaxon
                             withProperties:@{
                                              @"IsTaxon": @"Yes",
                                              @"Suggestions": @"Yes",
                                              @"Common Ancestor": @"No",
                                              @"Suggestion Rank": @(indexPath.item+1),
                                              @"Via": @"List",
                                              }];
            [self.delegate taxaSearchViewControllerChoseTaxon:[[self.scores objectAtIndex:indexPath.item] exploreTaxon]
                                              chosenViaVision:YES];
        }
    } else {
        if (indexPath.section == 1) {
            [[Analytics sharedClient] event:kAnalyticsEventChoseTaxon
                             withProperties:@{
                                              @"IsTaxon": @"No",
                                              @"Suggestions": @"No",
                                              @"Common Ancestor": @"No",
                                              @"Via": @"List",
                                              }];
            [self.delegate taxaSearchViewControllerChoseSpeciesGuess:self.searchController.searchBar.text];
        } else if (self.searchResults.count > 0) {
            ExploreTaxonRealm *etr = [self.searchResults objectAtIndex:indexPath.item];
            [self.delegate taxaSearchViewControllerChoseTaxon:etr
                                              chosenViaVision:NO];
            [[Analytics sharedClient] event:kAnalyticsEventChoseTaxon
                             withProperties:@{
                                              @"IsTaxon": @"Yes",
                                              @"Suggestions": @"No",
                                              @"Common Ancestor": @"No",
                                              @"Via": @"List",
                                              }];
        } else {
            // shouldn't happen, do nothing
        }
    }
}

#pragma mark - Table view data source
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self showingSuggestions]) {
        return 80;
    } else {
        return 60;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self showingSuggestions]) {
        return self.commonAncestor ? 2 : 1;
    } else if (self.searchController.searchBar.text.length >= MIN_CHARS_TAXA_SEARCH) {
        return self.allowsFreeTextSelection ? 2 : 1;
    } else if (self.scores.count > 0) {
        if (self.commonAncestor) {
            return 2;
        } else {
            return 1;
        }
    } else {
        return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self showingSuggestions]) {
        if (self.commonAncestor) {
            if (section == 0) {
                NSString *base = NSLocalizedString(@"We're pretty sure this is in the %1$@ %2$@.",
                                                   @"comment for common ancestor suggestion. %1$@ is the rank name (order, family), whereas %2$@ is the actual rank (Animalia, Insecta)");
                return [NSString stringWithFormat:base,
                        self.commonAncestor.rankName, self.commonAncestor.scientificName];
            } else {
                return NSLocalizedString(@"Here are our top ten species suggestions:", nil);
            }
        } else if (self.scores.count > 0) {
            return NSLocalizedString(@"We're not confident enough to make a recommendation, but here are our top 10 suggestions.", nil);
        }
    } else {
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
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self showingSuggestions]) {
        if (self.commonAncestor) {
            if (section == 0) {
                return 1;
            } else {
                return self.scores.count;
            }
        } else {
            return self.scores.count;
        }
    } else {
        if (self.allowsFreeTextSelection) {
            if (self.searchController.searchBar.text.length >= MIN_CHARS_TAXA_SEARCH) {
                if (section == 0) {
                    return self.searchResults.count;
                } else {
                    return 1;
                }
            } else {
                return 0;
            }
        } else {
            if (self.searchController.searchBar.text.length >= MIN_CHARS_TAXA_SEARCH) {
                return self.searchResults.count;
            } else {
                return 0;
            }
        }
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if ([self showingSuggestions] && self.scores.count > 0) {
        if (self.commonAncestor && section == 0) {
            return nil;
        } else {
            if (self.creditNames && self.creditNames.count == 3) {
                NSString *base = NSLocalizedString(@"Suggestions based on observations and identifications provided by the iNaturalist community, including %@, %@, %@, and many others.", nil);
                return [NSString stringWithFormat:base, self.creditNames[0], self.creditNames[1], self.creditNames[2]];
            } else {
                return NSLocalizedString(@"Suggestions based on observations and identifications provided by the iNaturalist community.", nil);
            }
        }
    } else {
        return nil;
    }
}

#pragma mark - TaxonDetailViewControllerDelegate

- (void)taxonDetailViewControllerClickedActionForTaxonId:(NSInteger)taxonId {
    
    [[Analytics sharedClient] event:kAnalyticsEventChoseTaxon
                     withProperties:@{
                                      @"IsTaxon": @"Yes",
                                      @"Suggestions": [self showingSuggestions] ? @"Yes" : @"No",
                                      @"Common Ancestor": ([self showingSuggestions] && taxonId == self.commonAncestor.taxonId) ? @"Yes" : @"No",
                                      @"Via": @"Details",
                                      }];

    ExploreTaxonRealm *etr = [ExploreTaxonRealm objectForPrimaryKey:@(taxonId)];
    [self.delegate taxaSearchViewControllerChoseTaxon:etr
                                      chosenViaVision:[self showingSuggestions]];
}

#pragma mark - TableView helpers

- (void)showTaxonId:(NSInteger)taxonId {
    ExploreTaxonRealm *etr = [ExploreTaxonRealm objectForPrimaryKey:@(taxonId)];
    if (etr) {
        TaxonDetailViewController *tdvc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle: nil] instantiateViewControllerWithIdentifier:@"TaxonDetailViewController"];
        tdvc.taxon = etr;
        tdvc.delegate = self;
        tdvc.showsActionButton = YES;
        if (CLLocationCoordinate2DIsValid(self.coordinate)) {
            tdvc.observationCoordinate = self.coordinate;
        } else if (self.observationToClassify && CLLocationCoordinate2DIsValid(self.observationToClassify.visibleLocation)) {
            tdvc.observationCoordinate = self.observationToClassify.visibleLocation;
        }
        [self.navigationController pushViewController:tdvc animated:YES];
    }
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
