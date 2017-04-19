//
//  TaxaSearchViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/30/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TaxonDetailViewController.h"
#import "TaxonVisualization.h"

@protocol TaxaSearchViewControllerDelegate <NSObject>
@optional
- (void)taxaSearchViewControllerChoseTaxon:(id <TaxonVisualization>)taxonId;
- (void)taxaSearchViewControllerChoseSpeciesGuess:(NSString *)speciesGuess;
- (void)taxaSearchViewControllerCancelled;
@end

@interface TaxaSearchViewController : UITableViewController <TaxonDetailViewControllerDelegate>
@property (nonatomic, weak) id <TaxaSearchViewControllerDelegate> delegate;
@property (nonatomic, strong) NSString *query;
@property (nonatomic, assign) BOOL hidesDoneButton;
@property (nonatomic, assign) BOOL allowsFreeTextSelection;
@end
