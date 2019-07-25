//
//  INatUITabBarController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/23/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TaxonVisualization.h"

@class Project;

@interface INatUITabBarController : UITabBarController

- (void)setUpdatesBadge;
- (void)triggerNewObservationFlowForTaxon:(id <TaxonVisualization>)taxon project:(Project *)project;
@end

extern NSString *HasMadeAnObservationKey;
