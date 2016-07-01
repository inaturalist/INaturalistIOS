//
//  TaxaSearchViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/30/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TaxaSearchController.h"
#import "TaxonDetailViewController.h"
#import "TaxonVisualization.h"

@protocol TaxaSearchViewControllerDelegate <NSObject>
@optional
- (void)taxaSearchViewControllerChoseTaxon:(id <TaxonVisualization>)taxonId;
- (void)taxaSearchViewControllerChoseSpeciesGuess:(NSString *)speciesGuess;
@end

@interface TaxaSearchViewController : UITableViewController <RecordSearchControllerDelegate, TaxonDetailViewControllerDelegate>
@property (nonatomic, strong) TaxaSearchController *taxaSearchController;
@property (nonatomic, strong) id <TaxaSearchViewControllerDelegate> delegate;
@property (nonatomic, strong) NSString *query;
@property (nonatomic, assign) BOOL hidesDoneButton;
@property (nonatomic, assign) BOOL allowsFreeTextSelection;

- (IBAction)clickedCancel:(id)sender;
- (void)showTaxon:(id <TaxonVisualization>)taxon;
- (void)clickedAccessory:(id)sender event:(UIEvent *)event;
@end
