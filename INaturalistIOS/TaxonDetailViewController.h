//
//  TaxonDetailViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/23/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

@import CoreLocation;

#import <UIKit/UIKit.h>
#import "TaxonVisualization.h"

@class TaxonPhotoPageViewController;

@protocol TaxonDetailViewControllerDelegate <NSObject>
@optional
- (void)taxonDetailViewControllerClickedActionForTaxonId:(NSInteger)taxonId;
@end

@interface TaxonDetailViewController : UITableViewController
@property (nonatomic) id <TaxonVisualization> taxon;
@property (nonatomic, weak) id <TaxonDetailViewControllerDelegate> delegate;
@property (nonatomic, weak) TaxonPhotoPageViewController *photoPageVC;
- (IBAction)actionTapped:(id)sender;
- (IBAction)infoTapped:(id)sender;
@property CLLocationCoordinate2D observationCoordinate;
@property BOOL showsActionButton;
@end
