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

#import "TaxaSearchViewController.h"
#import "ImageStore.h"
#import "TaxonPhoto.h"
#import "TaxonDetailViewController.h"
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

@interface TaxaSearchViewController () <UISearchResultsUpdating, UISearchControllerDelegate, UITableViewDelegate, UITableViewDataSource>
@property UISearchController *searchController;
@property RLMResults <ExploreTaxonRealm *> *searchResults;
@property RLMNotificationToken *searchResultsToken;
@property NSArray <ExploreTaxonScore *> *scores;
@property NSArray <NSString *> *creditNames;
@property ExploreTaxonRealm *commonAncestor;
@property BOOL showingSuggestions;
@property BOOL showingNearbySuggestionsOnly;

@property IBOutlet UIImageView *headerImageView;
@property IBOutlet UITableView *tableView;
@property IBOutlet NSLayoutConstraint *headerHeightConstraint;
@property IBOutlet UIView *loadingView;
@property IBOutlet UILabel *statusLabel;
@property IBOutlet UIActivityIndicatorView *loadingSpinner;
@property IBOutlet UIView *suggestionHeaderView;
@property UIBarButtonItem *nearbySwitchButton;

@property UIToolbar *doneToolbar;
@end

@implementation TaxaSearchViewController


#pragma mark - UISearchControllerDelegate

- (void)willPresentSearchController:(UISearchController *)searchController {
    self.headerHeightConstraint.constant = 0.0f;
    [self.view setNeedsLayout];
    
    self.showingSuggestions = NO;
    [self.tableView reloadData];
}

- (void)didPresentSearchController:(UISearchController *)searchController {
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

// https://stackoverflow.com/a/31245380/3796488
- (BOOL)shouldQueryAPI {
    // ex. "櫻花" means "cherry blossom" in Chinese.
    NSInteger minCharsTaxaSearch = 3;
    BOOL isHan = ([self.searchController.searchBar.text rangeOfString:@"\\p{Han}" options:NSRegularExpressionSearch].location != NSNotFound);
    if (isHan) {
        minCharsTaxaSearch = 1;
    }
    BOOL hasEnoughChars = (self.searchController.searchBar.text.length >= minCharsTaxaSearch);
    return hasEnoughChars;
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
    if (![self shouldQueryAPI]) {
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
    
    // filter out inactive taxa
    results = [results objectsWhere:@"isActive = TRUE"];
    
    NSArray *sorts = @[
        [RLMSortDescriptor sortDescriptorWithKeyPath:@"rankLevel"
                                           ascending:NO],
        [RLMSortDescriptor sortDescriptorWithKeyPath:@"observationCount"
                                           ascending:NO]
    ];
    
    self.searchResults = [results sortedResultsUsingDescriptors:sorts];
    
    // invalidate & re-create the update token for the new search results
    if (self.searchResultsToken) {
        [self.searchResultsToken invalidate];
    }
    
    __weak typeof(self)weakSelf = self;
    self.searchResultsToken = [self.searchResults addNotificationBlock:^(RLMResults * _Nullable results, RLMCollectionChange * _Nullable change, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
        });
    }];
    
    [self.tableView reloadData];
}

- (IBAction)clickedCancel:(UIControl *)control {
    [self.delegate taxaSearchViewControllerCancelled];
}

#pragma mark - UIViewController lifecycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.coordinate = kCLLocationCoordinate2DInvalid;
        
        // default to only showing nearby suggestions
        self.showingNearbySuggestionsOnly = YES;
    }
    return self;
}

- (void)dealloc {
    [self.searchResultsToken invalidate];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.doneToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                          target:nil
                                                                          action:nil];
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                          target:self
                                                                          action:@selector(kbDoneTapped)];
    self.doneToolbar.items = @[flex, doneBtn];

    UISwitch *switcher = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    self.nearbySwitchButton = [[UIBarButtonItem alloc] initWithCustomView:switcher];
    self.nearbySwitchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:nil];
    self.navigationItem.rightBarButtonItem = self.nearbySwitchButton;
    
    // setup the search controller
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = false;
    self.searchController.searchBar.placeholder = NSLocalizedString(@"Look up a species by name",
                                                                    @"placeholder text for taxon search bar");
    self.searchController.searchBar.inputAccessoryView = self.doneToolbar;
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
    
    // this is the callback for our suggestions api call
    INatAPISuggestionsCompletionHandler done = ^(NSArray *suggestions, ExploreTaxon *parent, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                self.tableView.backgroundView = self.loadingView;
                self.loadingSpinner.hidden = YES;
                self.statusLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Cannot load suggestions: %@",
                                                                                     @"error when loading suggestions. %@ is the error message"),
                                         error.localizedDescription];
            } else {
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
        [self showNoSuggestions];
    } else if (self.imageToClassify) {
        [self loadAndShowImageSuggestionsWithCompletion:done];
    } else if (self.observationToClassify && self.observationToClassify.sortedObservationPhotos.count > 0) {
        [self loadAndShowObservationSuggestionsWithCompletion:done];
    } else {
        // no suggestions without a photo
        [self showNoSuggestions];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // start the taxon search ui right away if we're not loading
    // suggestions
    if (!self.showingSuggestions) {
        // have to enqueue this, otherwise it's too early to have
        // the searchBar -becomeFirstResponder, even in -viewDidAppear:
        dispatch_async(dispatch_get_main_queue(), ^{
            // start the search UI right away
            [self.searchController setActive:YES];
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
    id <INatPhoto> op = [[self.observationToClassify sortedObservationPhotos] firstObject];
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


- (void)changeSuggestionsFilter {
    self.showingNearbySuggestionsOnly = !self.showingNearbySuggestionsOnly;
    [self.tableView reloadData];
}

#pragma mark - UIButton targets

- (void)kbDoneTapped {
    [self.searchController.searchBar endEditing:YES];
}

#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self showingSuggestions]) {
        
        // switcher cell is the last TV section
        if ((self.commonAncestor && indexPath.section == 2) || (!self.commonAncestor && indexPath.section == 1)) {
            SwitcherCell *cell = [tableView dequeueReusableCellWithIdentifier:@"switcher"
                                                                 forIndexPath:indexPath];
            
            cell.switchLabel.text = NSLocalizedString(@"Show nearby suggestions only", nil);
            cell.switchLabel.numberOfLines = 0;
            cell.switcher.on = self.showingNearbySuggestionsOnly;
            [cell.switcher addTarget:self
                              action:@selector(changeSuggestionsFilter)
                    forControlEvents:UIControlEventValueChanged];
            
            return cell;
        }
        
        TaxonSuggestionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"suggestion"
                                                                    forIndexPath:indexPath];
        
        ExploreTaxonScore *ts = nil;
        id <TaxonVisualization> taxon = nil;
        if (indexPath.section == 0 && self.commonAncestor) {
            taxon = self.commonAncestor;
        } else {
            if (self.showingNearbySuggestionsOnly) {
                ts = [[self nearbyScores] objectAtIndex:indexPath.item];
            } else {
                ts = [self.scores objectAtIndex:indexPath.item];
            }
            taxon = [ts exploreTaxon];
        }
        
        if (ts) {
            NSString *reason = @"";
            if (ts.visionScore > 0 && ts.frequencyScore > 0) {
                reason = NSLocalizedString(@"Visually Similar / Expected Nearby", @"basis for a species suggestion");
            } else if (ts.visionScore > 0) {
                reason = NSLocalizedString(@"Visually Similar", @"basis for a species suggestion");
            } else if (ts.frequencyScore > 0) {
                reason = NSLocalizedString(@"Expected Nearby", @"basis for a suggestion");
            }
            cell.comment.text = reason;
        } else {
            cell.comment.text = nil;
        }
        
        UIImage *iconicTaxonImage = [[ImageStore sharedImageStore] iconicTaxonImageForName:taxon.iconicTaxonName];
        if (self.showingSuggestions && taxon.representativePhotoUrl) {
            [cell.image setImageWithURL:taxon.representativePhotoUrl
                       placeholderImage:iconicTaxonImage];
        } else if (taxon.photoUrl) {
            [cell.image setImageWithURL:taxon.photoUrl
                       placeholderImage:iconicTaxonImage];
        } else {
            [cell.image setImage:iconicTaxonImage];
        }
        
        cell.primaryName.text = taxon.displayFirstName;
        if (taxon.displayFirstNameIsItalicized) {
            cell.primaryName.font = [UIFont italicSystemFontOfSize:cell.primaryName.font.pointSize];
        }
        
        cell.secondaryName.text = taxon.displaySecondName;
        if (taxon.displaySecondNameIsItalicized) {
            cell.secondaryName.font = [UIFont italicSystemFontOfSize:cell.secondaryName.font.pointSize];
        } else {
            cell.secondaryName.font = [UIFont systemFontOfSize:cell.secondaryName.font.pointSize];
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
        if ((self.commonAncestor && indexPath.section == 2) || (!self.commonAncestor && indexPath.section == 1)) {
            // no accessory for switcher cell but let's be safe
            return;
        } else if (indexPath.section == 0 && self.commonAncestor) {
            [self showTaxonId:self.commonAncestor.taxonId];
        } else {
            ExploreTaxonScore *ets = nil;
            if (self.showingNearbySuggestionsOnly) {
                ets = [[self nearbyScores] objectAtIndex:indexPath.item];
            } else {
                ets = [self.scores objectAtIndex:indexPath.item];
            }
            
            ExploreTaxon *taxon = ets.exploreTaxon;
            [self showTaxonId:taxon.taxonId];
        }
    } else {
        if (self.searchResults.count > 0 && indexPath.section == 0) {
            
            ExploreTaxonRealm *taxon = [self.searchResults objectAtIndex:indexPath.item];
            [self showTaxonId:taxon.taxonId];
        } else {
            // do nothing
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self showingSuggestions]) {
        if ((self.commonAncestor && indexPath.section == 2) || (!self.commonAncestor && indexPath.section == 1)) {
            // be safe for switcher cell
            return;
        } else if (indexPath.section == 0 && self.commonAncestor) {
            [self.delegate taxaSearchViewControllerChoseTaxon:self.commonAncestor
                                              chosenViaVision:YES];
        } else {
            ExploreTaxonScore *ets = nil;
            if (self.showingNearbySuggestionsOnly) {
                ets = [[self nearbyScores] objectAtIndex:indexPath.item];
            } else {
                ets = [self.scores objectAtIndex:indexPath.item];
            }
            
            ExploreTaxon *taxon = ets.exploreTaxon;
            
            [self.delegate taxaSearchViewControllerChoseTaxon:taxon
                                              chosenViaVision:YES];
        }
    } else {
        if (indexPath.section == 1) {
            [self.delegate taxaSearchViewControllerChoseSpeciesGuess:self.searchController.searchBar.text];
        } else if (self.searchResults.count > 0) {
            ExploreTaxonRealm *etr = [self.searchResults objectAtIndex:indexPath.item];
            [self.delegate taxaSearchViewControllerChoseTaxon:etr
                                              chosenViaVision:NO];
        } else {
            // shouldn't happen, do nothing
        }
    }
}

#pragma mark - Table view data source
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self showingSuggestions]) {
        if ((self.commonAncestor && indexPath.section == 2) || (!self.commonAncestor && indexPath.section == 1)) {
            // nearby switch, 80 pts for second row
            return 80;
        } else {
            return 80;
        }
    } else {
        return 60;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self showingSuggestions]) {
        if (self.scores && self.scores.count > 0) {
            return self.commonAncestor ? 3 : 2;
        } else {
            return 1;
        }
    } else if ([self shouldQueryAPI]) {
        return self.allowsFreeTextSelection ? 2 : 1;
    } else if (self.scores.count > 0) {
        if (self.commonAncestor) {
            return 2;
        } else {
            return 1;
        }
    } else {
        return 1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self showingSuggestions]) {
        if ((self.commonAncestor && section == 2) || (!self.commonAncestor && section == 1)) {
            return NSLocalizedString(@"Nearby Suggestions Filter", nil);
        } else {
            if (self.commonAncestor) {
                if (section == 0) {
                    NSString *base = NSLocalizedString(@"We're pretty sure this is in the %1$@ %2$@.",
                                                       @"comment for common ancestor suggestion. %1$@ is the rank name (order, family), whereas %2$@ is the actual rank (Animalia, Insecta)");
                    return [NSString stringWithFormat:base,
                            self.commonAncestor.rankName, self.commonAncestor.scientificName];
                } else {
                    return NSLocalizedString(@"Here are our top suggestions:", nil);
                }
            } else if (self.scores.count > 0) {
                return NSLocalizedString(@"We're not confident enough to make a recommendation, but here are our top suggestions.", nil);
            } else {
                return NSLocalizedString(@"We're not confident enough to make a recommendation.", nil);
            }
        }
    } else {
        if (self.allowsFreeTextSelection) {
            if ([self shouldQueryAPI] && section == 0) {
                if (self.searchResults.count > 0) {
                    return @"iNaturalist";
                } else {
                    return NSLocalizedString(@"No iNaturalist Results", nil);
                }
            } else if ([self shouldQueryAPI] && section == 1) {
                return NSLocalizedString(@"Placeholder", nil);
            }
        }
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self showingSuggestions]) {
        if ((self.commonAncestor && section == 2) || (!self.commonAncestor && section == 1)) {
            // don't show the switcher until we've had a chance to load the suggestions
            if (self.scores && self.scores.count > 0) {
                return 1;
            } else {
                return 0;
            }
        } else {
            if (self.commonAncestor) {
                if (section == 0) {
                    return 1;
                } else {
                    if (self.showingNearbySuggestionsOnly) {
                        return [[self nearbyScores] count];
                    } else {
                        return self.scores.count;
                    }
                }
            } else {
                if (self.showingNearbySuggestionsOnly) {
                    return [[self nearbyScores] count];
                } else {
                    return self.scores.count;
                }
            }
        }
    } else {
        if (self.allowsFreeTextSelection) {
            if ([self shouldQueryAPI]) {
                if (section == 0) {
                    return self.searchResults.count;
                } else {
                    return 1;
                }
            } else {
                return 0;
            }
        } else {
            if ([self shouldQueryAPI]) {
                return self.searchResults.count;
            } else {
                return 0;
            }
        }
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if ([self showingSuggestions] && self.scores.count > 0) {
        if ((self.commonAncestor && section == 1) || section == 0) {
            if (self.creditNames && self.creditNames.count == 3) {
                NSString *base = NSLocalizedString(@"Suggestions based on observations and identifications provided by the iNaturalist community, including %@, %@, %@, and many others.", nil);
                return [NSString stringWithFormat:base, self.creditNames[0], self.creditNames[1], self.creditNames[2]];
            } else {
                return NSLocalizedString(@"Suggestions based on observations and identifications provided by the iNaturalist community.", nil);
            }
        }
    }
    
    return nil;
}

#pragma mark - TaxonDetailViewControllerDelegate

- (void)taxonDetailViewControllerClickedActionForTaxonId:(NSInteger)taxonId {
    ExploreTaxonRealm *etr = [ExploreTaxonRealm objectForPrimaryKey:@(taxonId)];
    [self.delegate taxaSearchViewControllerChoseTaxon:etr
                                      chosenViaVision:[self showingSuggestions]];
}

#pragma mark - TableView helpers

- (void)showTaxonId:(NSInteger)taxonId {
    ExploreTaxonRealm *etr = [ExploreTaxonRealm objectForPrimaryKey:@(taxonId)];
    if (etr) {
        TaxonDetailViewController *tdvc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle: nil] instantiateViewControllerWithIdentifier:@"TaxonDetailViewController"];
        tdvc.taxonId = taxonId;
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
    [cell.taxonImageView cancelImageDownloadTask];
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
    
    cell.taxonNameLabel.text = etr.displayFirstName;
    if (etr.displayFirstNameIsItalicized) {
        cell.taxonNameLabel.font = [UIFont italicSystemFontOfSize:cell.taxonNameLabel.font.pointSize];
    }
    
    cell.taxonSecondaryNameLabel.text = etr.displaySecondName;
    if (etr.displaySecondNameIsItalicized) {
        cell.taxonSecondaryNameLabel.font = [UIFont italicSystemFontOfSize:cell.taxonSecondaryNameLabel.font.pointSize];
    }
    
    cell.accessoryType = UITableViewCellAccessoryDetailButton;
    
    return cell;
}

- (NSArray *)nearbyScores {
    static NSPredicate *nearbyPredicate = nil;
    
    if (!nearbyPredicate) {
        nearbyPredicate = [NSPredicate predicateWithBlock:^BOOL(ExploreTaxonScore *score, NSDictionary *bindings) {
            return score.frequencyScore > 0;
        }];
    }
    
    return [self.scores filteredArrayUsingPredicate:nearbyPredicate];
}

@end



@implementation SwitcherCell

@end
