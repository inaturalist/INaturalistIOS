//
//  INatUITabBarController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/23/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Taxon;
@class Project;

@interface INatUITabBarController : UITabBarController

- (void)setUpdatesBadge;
- (void)triggerNewObservationFlowForTaxon:(Taxon *)taxon project:(Project *)project;
@end

extern NSString *HasMadeAnObservationKey;
