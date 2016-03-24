//
//  TaxonDetailViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/23/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Taxon;

@protocol TaxonDetailViewControllerDelegate <NSObject>
@optional
- (void)taxonDetailViewControllerClickedActionForTaxon:(Taxon *)taxon;
@end

@interface TaxonDetailViewController : UITableViewController <UIActionSheetDelegate>

@property (nonatomic, strong) Taxon *taxon;
@property (nonatomic, assign) NSInteger taxonId;

@property (nonatomic, weak) id <TaxonDetailViewControllerDelegate> delegate;

- (IBAction)clickedActionButton:(id)sender;
@end
