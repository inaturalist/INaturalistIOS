//
//  AddIdentificationViewController.h
//  iNaturalist
//
//  Created by Ryan Waggoner on 10/23/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TaxaSearchViewController.h"
#import "ObservationVisualization.h"
#import "TaxonVisualization.h"

@interface AddIdentificationViewController : UITableViewController <TaxaSearchViewControllerDelegate>

@property (nonatomic, strong) id <ObservationVisualization> observation;
@property (nonatomic, strong) id <TaxonVisualization> taxon;

@end
