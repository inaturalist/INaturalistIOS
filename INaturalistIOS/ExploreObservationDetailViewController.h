//
//  ExploreObservationDetailViewController.h
//  Explore Prototype
//
//  Created by Alex Shepard on 10/10/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SlackTextViewController/Classes/SLKTextViewController.h>

@class ExploreObservation;

@interface ExploreObservationDetailViewController : SLKTextViewController

@property ExploreObservation *observation;

@end

