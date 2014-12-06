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
#import "Taxon.h"

@protocol TaxaSearchViewControllerDelegate <NSObject>
@optional
- (void)taxaSearchViewControllerChoseTaxon:(Taxon *)taxon;
@end

@interface TaxaSearchViewController : UITableViewController <RecordSearchControllerDelegate, TaxonDetailViewControllerDelegate>
@property (nonatomic, strong) TaxaSearchController *taxaSearchController;
@property (nonatomic, strong) Taxon *taxon;
@property (nonatomic, strong) NSDate *lastRequestAt;
@property (nonatomic, strong) id <TaxaSearchViewControllerDelegate> delegate;
@property (nonatomic, strong) NSString *query;
@property (nonatomic, assign) BOOL hidesDoneButton;
- (IBAction)clickedCancel:(id)sender;
- (void)showTaxon:(Taxon *)taxon;
- (void)showTaxon:(Taxon *)taxon inNavigationController:(UINavigationController *)navigationController;
- (void)clickedAccessory:(id)sender event:(UIEvent *)event;
- (UITableViewCell *)cellForTaxon:(Taxon *)taxon inTableView:(UITableView *)tableView;
- (void)loadRemoteTaxaWithURL:(NSString *)url;
@end
