//
//  AddIdentificationViewController.h
//  iNaturalist
//
//  Created by Ryan Waggoner on 10/23/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TaxaSearchViewController.h"

@class Observation;

@interface AddIdentificationViewController : UITableViewController <TaxaSearchViewControllerDelegate>

@property (nonatomic, strong) Observation *observation;
@property (nonatomic, strong) Taxon *taxon;

@end
