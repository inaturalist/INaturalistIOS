//
//  TaxonDetailViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/23/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TaxonVisualization.h"

@protocol TaxonDetailViewControllerDelegate <NSObject>
@optional
- (void)taxonDetailViewControllerClickedActionForTaxonId:(NSInteger)taxonId;
@end

@interface TaxonDetailViewController : UITableViewController
@property (nonatomic) id <TaxonVisualization> taxon;
@property (nonatomic, weak) id <TaxonDetailViewControllerDelegate> delegate;
- (IBAction)clickedActionButton:(id)sender;
@end
