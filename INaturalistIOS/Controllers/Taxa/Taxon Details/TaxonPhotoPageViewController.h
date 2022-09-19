//
//  TaxonPhotoPageViewController.h
//  iNaturalist
//
//  Created by Alex Shepard on 5/23/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ExploreTaxonRealm.h"

@interface TaxonPhotoPageViewController : UIPageViewController
@property ExploreTaxonRealm *taxon;
- (void)reloadPages;
@end
