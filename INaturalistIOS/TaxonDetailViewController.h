//
//  TaxonDetailViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/23/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Three20/Three20.h>
#import "ObservationDetailViewController.h"

@class Taxon;

@interface TaxonDetailViewController : UITableViewController <TTImageViewDelegate, ObservationDetailViewControllerDelegate>
@property (nonatomic, strong) Taxon *taxon;
@property (nonatomic, strong) NSMutableDictionary *sectionHeaderViews;
- (void)scaleHeaderView:(BOOL)animated;
- (IBAction)clickedViewWikipedia:(id)sender;
@end
